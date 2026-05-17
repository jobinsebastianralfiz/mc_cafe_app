# Shift4 Payment Gateway Integration Plan

> **Project:** MaiCafe App
> **Date:** 2026-02-23
> **Status:** Approved for Development
> **Payment Gateway:** [Shift4](https://shift4.com)
> **Stack:** Laravel (Backend API) + Flutter (Mobile App)

---

## 1. Architecture Overview

Since Flutter has no official Shift4 SDK, the recommended approach is **client-side card tokenization via Shift4's REST API + backend charge creation**. Card data never touches your server — Flutter sends it directly to Shift4, gets a one-time token, then passes only the token to your backend.

```
Flutter App                        Laravel Backend              Shift4 API
───────────────────────────────    ───────────────────────────  ──────────────
1. User fills cart & taps Checkout
2. POST /api/orders/checkout  ──→  Create order (status=pending)
   payment_method=online           Return order_id + amount
                            ←──
3. Show card input form
4. POST card data ─────────────────────────────────────────→  POST /tokens
   (using Shift4 public key)                                   (public key auth)
                                                          ←──  { token_id }

5. POST /api/orders/{id}/payment/initiate  ──→  Verify order ownership
   { token_id }                                 Create Shift4 charge  ──→  POST /charges
                                                                      ←──  charge object
                                                If captured immediately:
                                                  order: paid + confirmed
                                                  ←──  { success: true }
                                                If 3DS required:
                                                  ←──  { redirect_url }

6a. If success: show order confirmed screen
6b. If redirect_url: open WebView for 3DS challenge
    Detect returnUrl redirect in WebView ────────────────────────────→  3DS complete
    Close WebView                                                        Shift4 redirects
    Poll GET /api/orders/{id} ──→  Return current order status           to returnUrl
    Show success/failure screen

(Background) Shift4 Webhook  ──────────────────────────────→  POST /api/webhooks/shift4
                                  Verify webhook signature          charge.captured event
                                  Update order status (backup)
```

---

## 2. Current State vs. What Changes

| Area | Current State | After Integration |
|------|--------------|-------------------|
| `checkout()` response | Returns placeholder `payment_url` | Returns `order_id + amount + currency` |
| `confirmPayment()` | Just updates DB, no verification | Replaced by webhook handler |
| `payment_reference` | Client-supplied (unverified) | Set to Shift4 `charge_id` |
| `payment_status` | `pending` / `paid` | `pending` / `paid` / `failed` |
| `orders` table | No Shift4 fields | Add `shift4_charge_id` column |

---

## 3. Backend Implementation

### 3.1 Environment Configuration

Add to `.env`:
```
SHIFT4_PUBLIC_KEY=pk_test_xxxxxxxxxxxx
SHIFT4_SECRET_KEY=sk_test_xxxxxxxxxxxx
SHIFT4_WEBHOOK_SECRET=whsk_xxxxxxxxxxxx
SHIFT4_API_URL=https://api.shift4.com
```

Also add to `.env.example` (without real values) for reference.

---

### 3.2 New `Shift4Service` Class

**File:** `app/Services/Shift4Service.php`

Responsibilities:
- `createCharge(array $params)` — POST to `/charges` using secret key (HTTP Basic Auth)
- `retrieveCharge(string $chargeId)` — GET `/charges/{id}` to verify payment status
- `verifyWebhookSignature(string $payload, string $signature)` — HMAC validation for webhook security

Uses Laravel's `Http` facade (Guzzle). No third-party Shift4 PHP SDK needed — Shift4's REST API uses standard HTTP Basic Auth.

**Auth format:** `Authorization: Basic base64(SECRET_KEY:)` (username = secret key, password = empty)

---

### 3.3 Database Migration

**File:** `database/migrations/YYYY_MM_DD_add_shift4_fields_to_orders_table.php`

Changes to `orders` table:
```
shift4_charge_id  VARCHAR(255) nullable   — stores the Shift4 charge ID
payment_status    update enum to include 'failed'  — current: pending/paid
```

Updated `payment_status` enum: `'pending'`, `'paid'`, `'failed'`

---

### 3.4 New API Endpoints

#### `POST /api/orders/{id}/payment/initiate`
**Auth:** `auth:sanctum` (protected)

**Request body:**
```json
{ "token_id": "tok_xxxxxxxxxxxx" }
```

**Logic:**
1. Find order by `id` + `user_id` (ownership check)
2. Verify `status=pending` and `payment_status=pending` (not already paid)
3. Convert `total` to minor units (e.g., £12.50 → `1250`)
4. Call `Shift4Service::createCharge()` with:
   - `amount`, `currency`, `card.token` (the token from Flutter)
   - `returnUrl` → `https://yourdomain.com/api/payment/return/{orderId}`
   - `description` → order number
   - `metadata` → `{ order_id, user_id }`
   - `Idempotency-Key` header → order ID (prevents duplicate charges)
5. Store `shift4_charge_id` on the order
6. **If charge captured immediately** (`charge.captured = true`):
   - Update order: `payment_status=paid`, `status=confirmed`, `payment_reference=charge_id`
   - Return `{ success: true, order: {...} }`
7. **If charge requires 3DS** (`charge.status = 'pending'`, `charge.redirect.redirectUrl` present):
   - Return `{ requires_action: true, redirect_url: "https://..." }`
8. **If charge failed:**
   - Update order: `payment_status=failed`
   - Return `{ success: false, message: "Payment declined" }`

---

#### `GET /api/payment/return/{orderId}`
**Auth:** Public (no auth — Shift4 calls this as a redirect)

This is the `returnUrl` Shift4 redirects to after 3DS completes. It:
1. Retrieves the Shift4 charge via `Shift4Service::retrieveCharge(order->shift4_charge_id)`
2. Verifies `charge.captured` status
3. Updates the order `payment_status` and `status` accordingly
4. Returns an HTML page that triggers a **deep link** back to the Flutter app:
   ```
   maicafe://payment/result?order_id=123&status=success
   ```
   The HTML uses a meta-refresh and `window.location` JS redirect to fire the deep link.

> **Note:** This route goes in `routes/web.php` (not `api.php`) since it returns HTML.

---

#### `POST /api/webhooks/shift4`
**Auth:** Public (no auth — Shift4 calls this), but **signature-verified**

Shift4 sends this for all charge events. Acts as a **reliable backup** — webhooks fire even if the user closes the app mid-3DS.

**Logic:**
1. Read raw request body + `Shift4-Signature` header
2. Verify HMAC signature using `SHIFT4_WEBHOOK_SECRET` — return `400` if invalid
3. Decode JSON payload, check event type
4. Handle `CHARGE_UPDATED` / `CHARGE_CAPTURED` events:
   - Find order by `shift4_charge_id` or `metadata.order_id`
   - If `charge.captured = true` → set `payment_status=paid`, `status=confirmed`
   - If `charge.status = failed` → set `payment_status=failed`
5. Return `200 OK` immediately (Shift4 retries on non-2xx)

---

### 3.5 Modify Existing `checkout()` Response

In `OrderController::checkout()`, update the `online` payment response block to remove the placeholder and return clean data for the Flutter app:

**Before (current):**
```php
'payment_url' => url('/api/orders/' . $order->id . '/pay'),  // placeholder
```

**After:**
```php
'payment' => [
    'required'   => true,
    'method'     => 'online',
    'amount'     => (float) $order->total,
    'currency'   => Setting::get('currency_code', 'GBP'),
    'initiate_url' => url('/api/orders/' . $order->id . '/payment/initiate'),
    'instructions' => 'Please complete card payment to confirm your order.',
],
```

---

### 3.6 Update / Remove `confirmPayment()` Placeholder

The current `POST /api/orders/{id}/payment/confirm` endpoint accepts an unverified `payment_reference` from the client and trusts it blindly. With Shift4:
- **Remove** this endpoint (or keep it but disable for `online` method)
- Payment confirmation now happens exclusively via:
  - The `initiate` endpoint (immediate capture)
  - The webhook handler (async / 3DS)
  - The `returnUrl` handler (3DS redirect)

---

### 3.7 Route Summary

```php
// routes/api.php — protected
Route::post('/orders/{id}/payment/initiate', [PaymentController::class, 'initiate']);

// routes/api.php — public
Route::post('/webhooks/shift4', [WebhookController::class, 'shift4']);

// routes/web.php — public (HTML response for deep link redirect)
Route::get('/payment/return/{orderId}', [PaymentController::class, 'returnUrl']);
```

---

## 4. Flutter Implementation

### 4.1 Card Input Form

Custom card input screen with the following fields:
- **Card Number** — formatted as `4242 4242 4242 4242`
- **Expiry Date** — formatted as `MM/YY`
- **CVV** — 3–4 digits, obscured
- **Cardholder Name** — plain text

Standard Flutter `TextFormField` widgets with input formatters. No SDK needed.

---

### 4.2 Client-Side Tokenization

Flutter calls Shift4's tokenization endpoint **directly** (bypassing the backend) using the **public key**:

```
POST https://api.shift4.com/tokens
Authorization: Basic <base64(PUBLIC_KEY:)>
Content-Type: application/x-www-form-urlencoded

number=4242424242424242&expMonth=12&expYear=2027&cvc=123&cardholderName=John+Doe
```

**Response:**
```json
{ "id": "tok_xxxxxxxxxxxxxxxx", "brand": "Visa", "last4": "4242", ... }
```

The `token.id` is single-use, expires quickly, and is safe to send to your backend. Card data never touches your Laravel server — this is PCI DSS compliant.

> **Public key** (`pk_test_...`) is safe to embed in the Flutter app source. Only the **secret key** must stay on the server.

---

### 4.3 Payment Flow in Flutter (Step-by-Step)

```
Step 1:  POST /api/orders/checkout
         Body: { payment_method: "online", order_type: "pickup" }
         → Receive: { order_id, amount, currency }

Step 2:  Show card input form

Step 3:  User submits card details
         → POST https://api.shift4.com/tokens (direct, public key)
         → Receive: { token_id }

Step 4:  POST /api/orders/{order_id}/payment/initiate
         Body: { token_id }

Step 5a: Response: { success: true }
         → Navigate to Order Confirmed screen

Step 5b: Response: { requires_action: true, redirect_url: "https://..." }
         → Open WebView with redirect_url
         → Monitor URL changes in WebView
         → When URL starts with "maicafe://" → parse result, close WebView
            OR: poll GET /api/orders/{id} every 3 seconds (max 10 polls)
         → Navigate to success or failure screen

Step 5c: Response: { success: false, message: "Payment declined" }
         → Show error message, allow retry
```

---

### 4.4 Deep Link Setup (for 3DS Return)

Register the `maicafe://` URI scheme so Flutter handles the return from 3DS:

**Android** — `AndroidManifest.xml`:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="maicafe" android:host="payment" />
</intent-filter>
```

**iOS** — `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array><string>maicafe</string></array>
    </dict>
</array>
```

Use the `app_links` or `uni_links` Flutter package to handle incoming deep links.

**Deep link format:** `maicafe://payment/result?order_id=123&status=success`

---

### 4.5 Recommended Flutter Packages

| Package | Purpose |
|---------|---------|
| `http` or `dio` | HTTP calls to Shift4 tokenization API and Laravel backend |
| `webview_flutter` | Render 3DS challenge page in-app |
| `app_links` | Handle deep link redirect after 3DS |

---

## 5. Order Status Flow (Updated)

```
Checkout API call
    → Order created:  status=pending,  payment_status=pending
    → shift4_charge_id stored after initiate call

Payment initiated:
    ├─ Captured immediately
    │      status=confirmed,  payment_status=paid
    │      payment_reference=charge_id
    │
    ├─ 3DS Required
    │      User completes 3DS in WebView
    │      returnUrl handler / webhook fires
    │      status=confirmed,  payment_status=paid
    │
    └─ Declined / Failed
           status=pending (stays — user can retry),  payment_status=failed
           (order can be cancelled by user if they give up)
```

---

## 6. Security Considerations

| Concern | How Handled |
|---------|------------|
| Card data on backend | Never — tokenized client-side with Shift4 public key |
| Amount manipulation from client | Amount read from server-side `orders.total`, never from Flutter request |
| Payment reference tampering | `confirmPayment()` removed; only webhook + Shift4 API verify charge |
| Webhook spoofing | HMAC-SHA256 signature verification using `SHIFT4_WEBHOOK_SECRET` |
| Duplicate charges | `Idempotency-Key: order_{id}` header on `POST /charges` |
| Order ownership | Check `order.user_id = auth()->id()` before initiating charge |
| Token reuse | Shift4 tokens are single-use and short-lived |
| Secret key exposure | Only in `.env` on server — never sent to Flutter |

---

## 7. Implementation Phases

| Phase | What | Files Affected |
|-------|------|----------------|
| **1** | `.env` config + `Shift4Service` class | `app/Services/Shift4Service.php`, `.env` |
| **2** | DB migration (`shift4_charge_id`, `payment_status=failed`) | new migration file |
| **3** | `POST /api/orders/{id}/payment/initiate` endpoint | `app/Http/Controllers/Api/PaymentController.php` |
| **4** | `GET /payment/return/{orderId}` return URL + deep link HTML | `app/Http/Controllers/PaymentController.php` |
| **5** | `POST /api/webhooks/shift4` webhook handler | `app/Http/Controllers/WebhookController.php` |
| **6** | Update `checkout()` — remove placeholder `payment_url` | `app/Http/Controllers/Api/OrderController.php` |
| **7** | Remove/disable old `confirmPayment()` for online method | `app/Http/Controllers/Api/OrderController.php` |
| **8** | Register all new routes | `routes/api.php`, `routes/web.php` |
| **9** | Flutter: card form + tokenization call | Flutter — new `PaymentScreen` widget |
| **10** | Flutter: WebView + deep link handler | Flutter — `WebViewScreen` + `app_links` setup |

---

## 8. Shift4 Account Setup (Before Development)

1. Sign up at [dev.shift4.com](https://dev.shift4.com)
2. Go to **Account Settings** → get test API keys:
   - Public key (`pk_test_...`)
   - Secret key (`sk_test_...`)
3. Configure **Webhook endpoint** in Shift4 dashboard:
   - URL: `https://yourdomain.com/api/webhooks/shift4`
   - Events: `CHARGE_UPDATED`, `CHARGE_CAPTURED`, `CHARGE_FAILED`
   - Copy the **Webhook Secret** (`whsk_...`) to `.env`
4. Set **Return URL domain** whitelist in Shift4 dashboard

---

## 9. Test Cards (Shift4 Sandbox)

| Scenario | Card Number | Expiry | CVV |
|----------|-------------|--------|-----|
| Successful payment (no 3DS) | `4242 4242 4242 4242` | Any future | Any |
| 3DS required | `4000 0000 0000 3220` | Any future | Any |
| Payment declined | `4000 0000 0000 0002` | Any future | Any |
| Insufficient funds | `4000 0000 0000 9995` | Any future | Any |

---

## 10. Key Notes

- **Pay-at-counter flow is unchanged** — Shift4 only integrates into the `online` payment path
- **Cart, wishlist, orders list** — no changes needed
- **Currency** — app uses `Setting::get('currency_code', 'GBP')`; Shift4 amounts must be in **minor units** (pence): multiply total × 100 and round to integer
- **Refunds** — Shift4 supports refund API (`POST /charges/{id}/refund`); can be added to admin panel later
- **Saved cards** — Shift4 supports Customer + Card storage for one-tap payments; can be added as Phase 2 feature
- **Apple Pay / Google Pay** — Shift4 iOS/Android SDKs support these; can be added via Flutter Method Channels in future

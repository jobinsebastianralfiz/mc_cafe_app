# MaiCafe — Stripe Implementation Plan

**Status:** Not started (0% built). Only `PaymentMethod` / `PaymentStatus` enums and a
vestigial `paymentUrl` field exist; the UI exposes "Pay at Counter" only.

**Source of truth:** `MaiCafe_Stripe_Flutter_Integration.md` (native PaymentSheet flow).

---

## ⚠️ Resolve this first — three conflicting payment contracts

Before any Flutter work, the backend contract must be pinned down. Today three
incompatible flows are specified across docs and code:

| Source | Endpoint | Flow style |
|---|---|---|
| `MaiCafe_Stripe_Flutter_Integration.md` | `POST /orders/{id}/payment/initiate` → `client_secret` | Native `flutter_stripe` PaymentSheet (recommended) |
| `design/API_IMPLEMENTATION_PLAN.md` | `POST /orders/{id}/payment/confirm` | endpoint named only, no flow |
| `lib/data/repositories/order_repository.dart:223` | reads `payment_url` / `initiate_url` from the **checkout** response | Hosted-redirect (webview) |

### Backend clarification questions (send before implementing)
1. Which endpoint is live on `dev.maicafeuk.com` — `payment/initiate`, `payment/confirm`, or a `payment_url` in the checkout response?
2. What is its response shape? Native SDK needs `{ client_secret, payment_intent_id }`; a redirect flow returns a hosted `payment_url`.
3. Publishable key: what is `pk_test_…` (and later `pk_live_…`), and where should the app read it (hardcoded vs. config endpoint)?
4. Is `POST /api/webhooks/stripe` registered and flipping `payment_status → paid`, `status → confirmed`? Test or live mode?
5. After payment, is `GET /orders/{id}` the confirmation read, and does it expose `payment_status`?

**Decision gate:**
- Answers point to `initiate` + `client_secret` → follow the plan below (recommended).
- Answers point to `payment_url` → much smaller webview task; this plan does not apply.

---

## Stripe keys

Three credentials exist; only one belongs in the app.

| Key | Looks like | Lives where | In the app? |
|---|---|---|---|
| **Publishable** | `pk_test_…` / `pk_live_…` | Flutter app (`main.dart`) | ✅ Yes — the only key in the app |
| **Secret** | `sk_test_…` / `sk_live_…` | Backend `.env` only | ❌ Never — shipping this is a serious leak |
| **Webhook signing** | `whsec_…` | Backend `.env` only | ❌ Never |

- The **publishable key is safe to embed** — it can only *create* payments, not move money. It is not a secret.
- The **secret key and webhook secret must never appear in Flutter code or git.** The backend dev owns those.
- **Test → live:** develop with `pk_test_…` (pairs with the test cards in §8). Swap to `pk_live_…` only at launch, when the backend swaps `sk_live_` + `whsec_`.

**Where to store the publishable key (don't hardcode `pk_live_`):**
- **Option A (simple):** branch off `ApiConfig.isDev` — return `pk_test_…` in dev, `pk_live_…` in prod. Keys are still compiled into the build, but at least never the wrong one for the environment.
- **Option B (preferred):** have the backend serve the publishable key from a small config endpoint (e.g. `GET /config` or the existing app-config call) and read it at startup. Nothing Stripe-related is then baked into the binary, and rotating keys needs no app release.

**Who to ask:** request only the **publishable key** (`pk_test_` now, `pk_live_` later) from the project owner / Stripe dashboard. The backend dev configures `sk_…` and `whsec_…` server-side themselves.

---

## Implementation plan — native PaymentSheet

Estimated ~½ day of Flutter work **once the backend contract is confirmed**.

**1. Dependency** (`pubspec.yaml`)
- Add `flutter_stripe: ^10.x`; run `flutter pub get`.
- Verify Android `minSdkVersion 21` and iOS `platform :ios, '13.0'` (Firebase already raised minSdk, so likely fine).

**2. Init** (`lib/main.dart`)
- After `StorageService.init()`: `Stripe.publishableKey = …;` then `await Stripe.instance.applySettings();`.
- Guard test vs. live key off `ApiConfig.isDev` (see "Stripe keys" below).

**3. Endpoint** (`lib/core/config/api_config.dart`)
- Add `static String orderPaymentInitiate(int id) => '/orders/$id/payment/initiate';` (match the backend-confirmed name).

**4. Repository** (`lib/data/repositories/order_repository.dart`)
- Add `Future<({String clientSecret, String intentId})> initiatePayment(int orderId)`.
- **Remove the vestigial `paymentUrl` / `initiate_url` parsing** to kill the contradictory third contract.

**5. Service** (`lib/core/services/payment_service.dart` — new)
- `processPayment({orderId, customerName, customerEmail})`: `initiatePayment` → `Stripe.instance.initPaymentSheet(...)` → `presentPaymentSheet()`. No exception = success.

**6. UI** (`lib/screens/payment/payment_method_screen.dart`)
- Add an **"Online Payment"** option (enum `PaymentMethod.online` already exists).
- In `_handleCheckout`: for `online`, after `checkout()` returns `order.id`, call `PaymentService.processPayment(...)`, then poll `GET /orders/{id}` for `paid`/`confirmed` before routing to the success screen. Keep `pay_at_counter` on its current direct path.
- Catch `StripeException` (cancel / declined) → toast; reconcile order state.

**7. Provider** (`lib/providers/order_provider.dart`)
- Thin pass-through + loading/error state for the payment step.

**8. Test** — Stripe test cards (guide §9): `4242 4242 4242 4242` success, `4000 0000 0000 0002` declined, `4000 0025 0000 3155` 3DS.

---

## Going live (guide §10)
- [ ] Swap `pk_test_` → `pk_live_`.
- [ ] Backend `.env` has `sk_live_` + `whsec_` (live webhook secret).
- [ ] Stripe live webhook registered: `https://dev.maicafeuk.com/api/webhooks/stripe`.
- [ ] Real-card smoke test (small amount).
- [ ] `APP_DEBUG=false` on the server.

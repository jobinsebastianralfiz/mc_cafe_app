# MaiCafe — Backend Push Notification Guide

**Audience:** Laravel backend developer
**Mobile target:** MaiCafe Flutter app (Android + iOS)
**Backend:** Laravel @ `maicafeuk.com`
**FCM project:** Firebase Cloud Messaging (HTTP v1 API)
**Last updated:** April 2026

---

## 0. Context

The Flutter app already:

- Generates an FCM token on each device via the Firebase SDK.
- Calls `POST /api/user/fcm-token` after login to send the token to the backend.
- Calls `DELETE /api/user/fcm-token` on logout to clear it.
- On notification tap, reads `data.order_id` and navigates to that order's details screen, otherwise opens the app home.

You need to:

1. Persist FCM tokens against authenticated users.
2. Wire two `/user/fcm-token` endpoints (POST + DELETE).
3. Install + configure the Firebase Admin SDK (PHP).
4. Add the **Notifications** section to the Admin Panel for sending pushes (audience: all users, specific user, etc.).
5. Send notifications in the exact payload contract the mobile app expects.

---

## 1. Firebase project info

You'll need this to configure the Admin SDK and verify which app you're targeting.

| Field | Value |
|---|---|
| Firebase Project ID | `maicafe-552cd` |
| Project Number | `355340288168` |
| Android app ID | `1:355340288168:android:185e5ca5c6e3cfba98829d` |
| iOS app ID | `1:355340288168:ios:bffdab616d18e52e98829d` |
| Android package | `com.maicafe.mc_cafe_app` |
| iOS bundle ID | `com.maicafe.mcCafeApp` |

**Service account JSON** (you will need to upload this to your server):

- Firebase Console → Project Settings → **Service accounts** → **Generate new private key**.
- Save it on the server **outside the web root**, e.g. `/var/www/maicafe/storage/firebase/service-account.json`.
- Add the path to `.env`: `FIREBASE_CREDENTIALS=/var/www/maicafe/storage/firebase/service-account.json`.
- Make sure the file is **chmod 600** and owned by the web user — it grants full admin access to the Firebase project.

**Never commit** this file to git. Add `storage/firebase/` to `.gitignore`.

---

## 2. Database

Add an `fcm_token` column on the `users` table (or a separate `user_devices` table if you want per-device support — single column is fine for MVP).

```php
// database/migrations/2026_04_27_000000_add_fcm_token_to_users_table.php
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('fcm_token', 512)->nullable()->after('remember_token');
        $table->index('fcm_token');
    });
}

public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropIndex(['fcm_token']);
        $table->dropColumn('fcm_token');
    });
}
```

Add `fcm_token` to the `User` model's `$fillable` and to `$hidden` (so it's never returned in API responses).

```php
// app/Models/User.php
protected $fillable = [..., 'fcm_token'];
protected $hidden  = [..., 'fcm_token'];
```

---

## 3. API endpoints

Both endpoints require Sanctum authentication.

### `POST /api/user/fcm-token`

**Headers**

```
Authorization: Bearer {sanctum_token}
Content-Type: application/json
Accept: application/json
```

**Body**

```json
{ "fcm_token": "dGhpcyBpcyBhIHNhbXBsZSB0b2tlbg..." }
```

**Validation**

- `fcm_token`: required, string, min:50, max:512.

**Behaviour**

- Upsert the value onto the authenticated user (`Auth::user()->update(['fcm_token' => $request->fcm_token])`).
- Idempotent — the app will call this on every cold start and after token refresh. Just overwrite.

**Response 200**

```json
{ "success": true, "message": "FCM token updated successfully." }
```

### `DELETE /api/user/fcm-token`

**Headers**

```
Authorization: Bearer {sanctum_token}
Accept: application/json
```

**Behaviour**

- Set the authenticated user's `fcm_token` to `NULL`.
- Called by the app **before** logout completes, so the auth token is still valid.

**Response 200**

```json
{ "success": true, "message": "FCM token cleared." }
```

### Sample controller

```php
// app/Http/Controllers/Api/FcmTokenController.php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class FcmTokenController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'fcm_token' => ['required', 'string', 'min:50', 'max:512'],
        ]);

        Auth::user()->update(['fcm_token' => $data['fcm_token']]);

        return response()->json([
            'success' => true,
            'message' => 'FCM token updated successfully.',
        ]);
    }

    public function destroy()
    {
        Auth::user()->update(['fcm_token' => null]);

        return response()->json([
            'success' => true,
            'message' => 'FCM token cleared.',
        ]);
    }
}
```

### Routes

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::post  ('/user/fcm-token', [FcmTokenController::class, 'store']);
    Route::delete('/user/fcm-token', [FcmTokenController::class, 'destroy']);
});
```

---

## 4. Install Firebase Admin SDK

Use `kreait/laravel-firebase` (the most maintained Laravel wrapper around the Firebase Admin SDK):

```bash
composer require kreait/laravel-firebase
php artisan vendor:publish --provider="Kreait\Laravel\Firebase\ServiceProvider"
```

`.env`

```
FIREBASE_CREDENTIALS=/var/www/maicafe/storage/firebase/service-account.json
FIREBASE_PROJECT=maicafe-552cd
```

`config/firebase.php` (already published) — verify it reads `FIREBASE_CREDENTIALS`.

---

## 5. Notification payload contract (CRITICAL)

The mobile app **routes notification taps based on the `data` map**. Send it correctly and taps land on the right screen automatically.

### General / broadcast push (e.g. promotion)

```json
{
  "notification": {
    "title": "20% off all coffees today!",
    "body":  "Tap to see what's brewing."
  },
  "data": {
    "type": "broadcast"
  }
}
```

→ Tapping just opens the app.

### Order status update (taps go to the order details screen)

```json
{
  "notification": {
    "title": "Your order is ready",
    "body":  "Order #1042 — collect at the counter."
  },
  "data": {
    "type": "order",
    "order_id": "1042"
  }
}
```

**Rules**

- All `data` values must be **strings** (FCM requirement). Cast IDs with `(string) $orderId`.
- The app accepts `order_id` or `orderId` as the key — prefer **`order_id`** (snake_case).
- `type` is informational; the app routes solely on the presence of `order_id`. Use `"order"` for order-related, `"broadcast"` for general.
- Do **not** put `order_id` in `notification` — it must be in `data`.

### Per-platform priority / sound (optional but recommended)

The Admin SDK in PHP supports merging `AndroidConfig` and `ApnsConfig` per send. Use **high priority** for time-sensitive order updates so they wake the device.

---

## 6. Sending notifications — sample service

```php
// app/Services/FcmService.php
namespace App\Services;

use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Firebase\Messaging\AndroidConfig;
use Kreait\Firebase\Messaging\ApnsConfig;
use Kreait\Laravel\Firebase\Facades\Firebase;

class FcmService
{
    /** Send to a single device token. */
    public function sendToToken(string $token, string $title, string $body, array $data = []): void
    {
        $message = $this->buildMessage($title, $body, $data)->toToken($token);
        Firebase::messaging()->send($message);
    }

    /** Send to many tokens (chunks of 500, FCM cap). Returns failure count. */
    public function sendToTokens(array $tokens, string $title, string $body, array $data = []): int
    {
        $tokens = array_values(array_filter(array_unique($tokens)));
        if (empty($tokens)) return 0;

        $message  = $this->buildMessage($title, $body, $data);
        $failures = 0;

        foreach (array_chunk($tokens, 500) as $chunk) {
            $report = Firebase::messaging()->sendMulticast($message, $chunk);

            // Clean up tokens that the server rejected as invalid/unregistered.
            foreach ($report->invalidTokens() as $bad) {
                \App\Models\User::where('fcm_token', $bad)->update(['fcm_token' => null]);
            }
            $failures += $report->failures()->count();
        }

        return $failures;
    }

    private function buildMessage(string $title, string $body, array $data): CloudMessage
    {
        // FCM requires every data value to be a string.
        $data = array_map(fn ($v) => (string) $v, $data);

        return CloudMessage::new()
            ->withNotification(Notification::create($title, $body))
            ->withData($data)
            ->withAndroidConfig(AndroidConfig::fromArray([
                'priority' => 'high',
                'notification' => [
                    'channel_id' => $this->channelFor($data),
                    'sound'      => 'default',
                ],
            ]))
            ->withApnsConfig(ApnsConfig::fromArray([
                'headers' => ['apns-priority' => '10'],
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'content-available' => 1,
                    ],
                ],
            ]));
    }

    private function channelFor(array $data): string
    {
        // Match the channel IDs created by the Flutter app.
        if (($data['type'] ?? null) === 'order' || isset($data['order_id'])) {
            return 'mc_cafe_orders';
        }
        return 'maicafe_notifications';
    }
}
```

### Use it from a controller / job

```php
// Send to all users with a token (broadcast)
$tokens = User::whereNotNull('fcm_token')->pluck('fcm_token')->all();
app(FcmService::class)->sendToTokens(
    $tokens,
    'New menu items added!',
    'Try our new seasonal lattes today.',
    ['type' => 'broadcast'],
);

// Send order status update to one user
$user = Order::find($orderId)->user;
app(FcmService::class)->sendToToken(
    $user->fcm_token,
    'Your order is ready',
    "Order #{$order->number} — collect at the counter.",
    ['type' => 'order', 'order_id' => $order->id],
);
```

**Always** call `sendToTokens` from a queued job for broadcasts — sending to thousands of tokens synchronously will block the request.

---

## 7. Admin Panel — Notifications page

UI requirements:

1. **Service Account JSON paste box + Save button** (one-time setup; stores the JSON to `storage/firebase/service-account.json`).
2. **Send Notification form**:
   - Title (max 100 chars)
   - Message / Body (max 240 chars)
   - Audience: `All Users` | `Specific User (search by email/phone)` | (future: groups, segments)
   - Optional: link to a specific order (would set `data.order_id`)
   - **Send Notification** button → fires a queued job
3. **Devices registered** counter at top right: `User::whereNotNull('fcm_token')->count()`.
4. **Send history** table (recommended — see §8 audit log).

---

## 8. Suggested audit log

Optional but very useful for support / debugging:

```php
// migration
Schema::create('push_notifications', function (Blueprint $table) {
    $table->id();
    $table->foreignId('sent_by')->constrained('users');
    $table->string('title');
    $table->text('body');
    $table->json('data')->nullable();
    $table->string('audience'); // 'all' | 'user:{id}' | 'segment:{name}'
    $table->unsignedInteger('recipients')->default(0);
    $table->unsignedInteger('failures')->default(0);
    $table->timestamps();
});
```

Persist a row each time the admin sends a push so support can answer "did the customer actually get notified?"

---

## 9. Test plan

Before declaring done, run through this:

- [ ] `POST /api/user/fcm-token` with a valid Sanctum token returns 200 and persists `fcm_token` on the row.
- [ ] `POST /api/user/fcm-token` without a token returns 401.
- [ ] `POST /api/user/fcm-token` with `fcm_token < 50 chars` returns 422.
- [ ] `DELETE /api/user/fcm-token` nulls the column.
- [ ] Service account JSON loads without error: `php artisan tinker` → `Kreait\Laravel\Firebase\Facades\Firebase::messaging();` returns an instance.
- [ ] Send a test push from the Admin Panel to a logged-in test device → notification appears.
- [ ] Send a push with `data.order_id = <real id>` → tapping the notification on the device opens that order's details screen.
- [ ] Send a push to a token you've manually corrupted → the row's `fcm_token` is automatically nulled (invalid token cleanup works).
- [ ] Send a broadcast to ~500 users via the queued job and check there are no timeouts.

---

## 10. Common pitfalls

| Symptom | Cause |
|---|---|
| `Permission denied` from Firebase SDK | service account JSON path wrong, or file not readable by web user |
| Push arrives but tap doesn't navigate | `order_id` is in `notification` instead of `data`, or sent as integer instead of string |
| Some users never receive pushes | Their `fcm_token` is `NULL` (never logged in since update) or stale (didn't clean up `invalidTokens()`) |
| Push delivered on Android but silent on iOS | APNs key not uploaded to Firebase Console, or iOS push capability missing in app build |
| Duplicate tokens for the same user | Single `fcm_token` column overwrites — that's fine. If you later need multi-device support, migrate to a `user_devices` table |

---

## Summary checklist

- [ ] Migration: `fcm_token` column on `users`
- [ ] Routes: `POST` + `DELETE /api/user/fcm-token`
- [ ] `FcmTokenController` implemented
- [ ] `kreait/laravel-firebase` installed
- [ ] Service account JSON saved to server (chmod 600, outside web root)
- [ ] `FIREBASE_CREDENTIALS` set in `.env`
- [ ] `FcmService` implemented (single-token + multicast + invalid-token cleanup)
- [ ] Admin Panel → Notifications page (service account upload + send form + recipient count)
- [ ] Queued job for broadcast sends
- [ ] (Recommended) `push_notifications` audit table
- [ ] Test plan in §9 passes

---

## API Reference (mirror of mobile-side doc)

**Base URL:** `https://maicafeuk.com/api`

### POST `/user/fcm-token`

```http
POST /api/user/fcm-token HTTP/1.1
Authorization: Bearer {sanctum_token}
Content-Type: application/json
Accept: application/json

{ "fcm_token": "..." }
```

→ `200 { "success": true, "message": "FCM token updated successfully." }`

### DELETE `/user/fcm-token`

```http
DELETE /api/user/fcm-token HTTP/1.1
Authorization: Bearer {sanctum_token}
Accept: application/json
```

→ `200 { "success": true, "message": "FCM token cleared." }`
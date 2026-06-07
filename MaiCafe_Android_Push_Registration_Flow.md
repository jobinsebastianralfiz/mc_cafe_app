# MaiCafe — Android Push Notification Registration Flow

**Platform:** Android
**Backend:** Laravel (maicafeuk.com)
**Mobile:** Flutter

This document explains exactly how an Android user ends up with their FCM token stored in the backend's `users.fcm_token` column, and how to verify it is working.

---

## 1. The full Android registration flow

```
[App start]                                               [Backend]
    │
    ├─ main.dart:39   Firebase.initializeApp()
    ├─ main.dart:47   NotificationService.initFcm()
    │       │
    │       ├─ requestPermission()  ── Android 13+ shows the system prompt
    │       └─ onTokenRefresh listener registered
    │
    ├─ AuthProvider.checkAuthStatus()
    │       └─ if already logged in:
    │            registerFcmToken()  ── auth_provider.dart:64
    │
[User logs in / verifies OTP / registers]
    │
    ├─ AuthProvider.login() ──► auth_provider.dart:171
    ├─ AuthProvider.verifyOtp() ──► auth_provider.dart:221
    │       │
    │       └─ NotificationService.registerFcmToken()
    │              │
    │              ├─ FirebaseMessaging.instance.getToken()
    │              │      ── Firebase SDK contacts Google FCM servers
    │              │      ── returns long string (e.g. "fXyZ...:APA91b...")
    │              │
    │              ├─ StorageService.setString('fcm_token', token)
    │              │      ── cached locally so we don't re-fetch
    │              │
    │              └─ ApiService.post('/user/fcm-token',          ──► POST https://maicafeuk.com/api/user/fcm-token
    │                                  body: {'fcm_token': '...'},     Authorization: Bearer <sanctum_token>
    │                                  Bearer auth)                     {"fcm_token": "fXyZ...:APA91b..."}
    │                                                                  │
    │                                                                  └─► Backend writes it to users.fcm_token
    │                                                                      for the authenticated user
    │
[Later — Firebase rotates the token]
    │
    └─ messaging.onTokenRefresh fires
            └─ if logged in: re-POST /user/fcm-token
```

---

## 2. Code references

| Step | File | Line |
|------|------|------|
| Firebase init | `lib/main.dart` | 39 |
| FCM service init | `lib/main.dart` | 47 |
| Token refresh listener | `lib/core/services/notification_service.dart` | 135 |
| `registerFcmToken()` definition | `lib/core/services/notification_service.dart` | 153 |
| `_postFcmToken()` (HTTP call) | `lib/core/services/notification_service.dart` | 191 |
| Trigger on app start (already logged in) | `lib/providers/auth_provider.dart` | 64 |
| Trigger after login | `lib/providers/auth_provider.dart` | 171 |
| Trigger after OTP verification | `lib/providers/auth_provider.dart` | 221 |
| Trigger after register flow | `lib/providers/auth_provider.dart` | 221 |
| Clear on logout | `lib/providers/auth_provider.dart` | 429 |
| Endpoint constant | `lib/core/config/api_config.dart` | 38 |

---

## 3. The HTTP request sent to the backend

```http
POST https://maicafeuk.com/api/user/fcm-token
Authorization: Bearer <sanctum_token>
Content-Type: application/json
Accept: application/json

{
  "fcm_token": "fXyZabc...:APA91b..."
}
```

Expected response:

```json
{
  "message": "FCM token updated successfully."
}
```

---

## 4. What "registered" means concretely

After a successful login, this row should exist on the backend:

```sql
SELECT id, email, fcm_token, updated_at
FROM users
WHERE email = 'your_test@account.com';
```

If `fcm_token` is **non-null and 100+ chars long** → the user is registered. The backend uses that exact string as the recipient when calling FCM.

---

## 5. Android-specific things to check if it's not working

### 5.1 User declined the system permission prompt (Android 13+)

`getToken()` still returns a token even without the prompt accepted, but **no notifications will display** in the system tray.

- Verify under **Settings → Apps → MAICAFE → Notifications**.
- Re-prompt by uninstalling/reinstalling the app, or toggle the permission manually.

### 5.2 `google-services.json` mismatch or missing

Confirm `android/app/google-services.json` matches the project ID in Firebase Console:

- Project ID expected: `maicafe-552cd`
- App ID expected: `1:355340288168:android:185e5ca5c6e3cfba98829d`

These values come from `firebase.json` at the project root.

### 5.3 `POST /user/fcm-token` is silently failing

The call is wrapped in a `try/catch` that swallows errors (`notification_service.dart:165`). If the backend route doesn't exist or returns 422, you'd never see it.

Add temporary debug logging in `lib/core/services/notification_service.dart`:

```dart
Future<void> _postFcmToken(String token) async {
  try {
    final res = await ApiService.instance.post(
      ApiConfig.fcmToken,
      body: {'fcm_token': token},
    );
    debugPrint('FCM register OK: ${res.statusCode} ${res.message}');
  } catch (e) {
    debugPrint('FCM register FAILED: $e');
    rethrow;
  }
}
```

Then watch `flutter logs` while logging in.

### 5.4 User logged in *before* this code shipped

Old sessions never trigger `registerFcmToken()` because the trigger sites are `login` / `verifyOtp` / `checkAuthStatus`. If a user has a stale session, either:

- ask them to log out and log back in, or
- call `registerFcmToken()` unconditionally on app start for already-authenticated users.

### 5.5 Notification channel mismatch

The Android default channel ID set in `AndroidManifest.xml` is:

```
maicafe_notifications
```

If the backend FCM payload references a different channel ID (`android.notification.channel_id`), Android 8+ will drop the notification. Either:

- omit `channel_id` in the payload (uses the default), or
- send `"channel_id": "maicafe_notifications"` (or `"mc_cafe_orders"` for order-related pushes).

---

## 6. Android manifest reference

The following is already configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- FCM defaults -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="maicafe_notifications" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
```

---

## 7. Quick end-to-end test

1. Build a debug APK on a real Android device:
   ```bash
   flutter run --release
   ```
2. Log in with a fresh test account (or log out and back in).
3. Watch `flutter logs` — there should be no errors from `_postFcmToken`.
4. On the backend, run:
   ```sql
   SELECT id, email, fcm_token FROM users WHERE email = 'your_test@account.com';
   ```
   The `fcm_token` column should be filled.
5. From the admin panel, send a test notification to that user → it should appear in the system tray.

---

## 8. Endpoint summary

| Method   | Endpoint               | Auth       | Purpose                          |
|----------|------------------------|------------|----------------------------------|
| `POST`   | `/api/user/fcm-token`  | Bearer     | Register / update device token   |
| `DELETE` | `/api/user/fcm-token`  | Bearer     | Clear token on logout            |

Both endpoints are configured in `lib/core/config/api_config.dart` as `ApiConfig.fcmToken`.
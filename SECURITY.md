# MaiCafe — Security Notes

Audit + checklist covering endpoint protection, credential handling, and Firebase configuration for the Flutter app and backend.

---

## 1. What's already secure

| Area | Status | Notes |
|---|---|---|
| API base URL | HTTPS-only | `lib/core/config/api_config.dart` → `https://maicafeuk.com/api` |
| Storage URL | HTTPS-only | `https://maicafeuk.com/storage` |
| iOS App Transport Security | Enforced | `NSAllowsArbitraryLoads = false` (no global HTTP bypass) |
| Android cleartext traffic | Blocked | `android:usesCleartextTraffic="false"` on the `<application>` tag |
| Hardcoded secrets in `lib/` | None | Verified via grep — only legitimate password-input fields |
| Auth token sent over wire | Bearer + TLS | Sanctum token in `Authorization: Bearer …` header, never in URL |
| 401 auto-logout | Wired | `ApiService.onUnauthorized` → clears auth data + redirects to login |
| FCM token cleared on logout | Yes | `NotificationService.clearFcmToken()` runs **before** local auth wipe |

---

## 2. Pending — recommended hardening

### 2.1 Move auth token from `SharedPreferences` → `flutter_secure_storage` (HIGH)

Current state: `StorageService` writes the bearer token to `SharedPreferences`, which on Android stores values in **plaintext XML** under `/data/data/<pkg>/shared_prefs/`. On a rooted device or via `adb backup`, the token can be read.

Recommendation: store **`authToken`**, **`refreshToken`**, and **`tokenType`** in `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences/Keystore on Android). Leave non-sensitive prefs (theme, language, cached menu data) in `SharedPreferences`.

This is a non-trivial change because `_storage.authorizationHeader` is currently synchronous and is read on every API call. The migration has two options:

1. **Cleanest:** make `ApiService` resolve the header per-request via `await`. Mechanical change but touches every HTTP method.
2. **Pragmatic:** load the token from secure storage **once at app start** into an in-memory cache, write-through on login/logout. Keeps callers synchronous.

Option 2 is the lower-risk path and matches how most production Flutter apps handle this.

### 2.2 Restrict Firebase API keys (MEDIUM)

The API key in `firebase_options.dart`, `google-services.json`, and `GoogleService-Info.plist` is **not a secret** — Google designs it to ship with the app — but it can be abused if unrestricted.

In Google Cloud Console → **APIs & Services → Credentials** for project `maicafe-552cd`:

- For the **Android key**: restrict to **Android apps** with package `com.maicafe.mc_cafe_app` and your release SHA-1/SHA-256 fingerprints (`./gradlew :app:signingReport` to get them).
- For the **iOS key**: restrict to **iOS apps** with bundle ID `com.maicafe.mcCafeApp`.
- Under **API restrictions** → restrict each key to only the Firebase APIs the app actually uses (Cloud Messaging, Identity Toolkit if you use Firebase Auth, etc.).

### 2.3 Enable Firebase App Check (MEDIUM)

App Check verifies that backend calls actually come from your app (not a script). Backend then validates the App Check token before honouring `/api/user/fcm-token` or other endpoints.

- iOS: DeviceCheck / App Attest provider.
- Android: Play Integrity provider.

Backend dev — see §2.5 of `MaiCafe_Backend_Push_Notification_Guide.md` for the verification step.

### 2.4 Build-time code obfuscation (LOW–MEDIUM)

Dart code is AOT-compiled in release, but symbol names are still readable. Build release with:

```bash
flutter build apk     --release --obfuscate --split-debug-info=./build/debug-symbols
flutter build appbundle --release --obfuscate --split-debug-info=./build/debug-symbols
flutter build ipa     --release --obfuscate --split-debug-info=./build/debug-symbols
```

Keep the `debug-symbols` directory **archived per release** — you'll need it to symbolicate stack traces from Crashlytics / Sentry.

### 2.5 Optional — certificate pinning (advanced)

Considered overkill for most apps. ATS + HSTS + a properly maintained CA chain already covers the realistic attack surface. Skip unless you have a specific compliance requirement, since pinning adds release-time risk if the cert rotates without an app update.

---

## 3. Files safe to commit / files that must NEVER be committed

### Safe to commit

- `lib/firebase_options.dart` — public API keys, identifies the project
- `android/app/google-services.json` — same
- `ios/Runner/GoogleService-Info.plist` — same

These are designed to ship in the binary. Restrict them via §2.2 instead of trying to hide them.

### NEVER commit

- Firebase **Service Account JSON** (used by the backend / admin panel) — this is a full admin credential. Lives only on the server, in `storage/firebase/` outside the web root, chmod 600, gitignored.
- APNs `.p8` private key — upload to Firebase Console then store offline, do not commit.
- Any release keystore (`.jks`, `.keystore`) or its passwords.
- Apple distribution `.p12` certificates.

The repo's `.gitignore` already covers build artifacts. Add the following lines if you'll be adding signing material to the project:

```
# Signing — never commit
android/key.properties
android/app/upload-keystore.jks
android/app/release-keystore.jks
ios/Runner/*.p8
ios/Runner/*.p12
**/.env
**/.env.local
```

---

## 4. Endpoint inventory (what the app talks to)

All over HTTPS. Bearer token required unless noted.

| Endpoint | Auth | Sensitive payload |
|---|---|---|
| `POST /auth/register` | No | password |
| `POST /auth/login` | No | password |
| `POST /auth/verify-email` | No | OTP |
| `POST /auth/forgot-password` | No | email only |
| `POST /auth/reset-password` | No | OTP + new password |
| `POST /auth/logout` | Yes | — |
| `GET  /user/profile` | Yes | — |
| `PUT  /user/profile` | Yes | profile fields |
| `DELETE /user/account` | Yes | password |
| `POST /user/fcm-token` | Yes | FCM device token |
| `DELETE /user/fcm-token` | Yes | — |
| `GET /products`, `/categories`, `/banners` | No | — |
| `GET/POST/PUT/DELETE /cart*` | Yes | — |
| `GET/POST /orders*` | Yes | — |
| `GET/POST/DELETE /wishlist*` | Yes | — |
| `GET/POST/PUT/DELETE /addresses*` | Yes | — |
| `GET/POST /coupons*` | Yes | — |
| `GET/POST /notifications*` | Yes | — |

No endpoints accept secrets in the URL — passwords/OTPs/tokens are always in the JSON body or `Authorization` header.

---

## 5. Threat model — what changed isn't enough for, and what to do

| Threat | Mitigation |
|---|---|
| Passive network attacker (Wi-Fi sniffer) | TLS — already protected |
| Active network attacker / MITM with a custom CA installed on victim device | TLS chains validate against system CAs; certificate pinning would harden further (see §2.5) |
| Stolen / lost device, no PIN | OS-level encryption + Keychain/Keystore once §2.1 lands |
| Rooted / jailbroken device | §2.1 (secure storage) — but no app-level fix is bulletproof against root |
| Reverse-engineering the APK to find endpoints | Endpoint URLs are not secrets — server-side authorization is what protects user data. §2.4 obfuscation makes this slower for a casual attacker |
| Abuse of Firebase API keys | §2.2 (key restrictions) + §2.3 (App Check) |
| Compromised admin panel | Out of scope for the Flutter app — backend's responsibility (rate-limit + 2FA on admin login) |

---

## 6. Pre-release checklist (run before each App Store / Play Store submission)

- [ ] No new `http://` URLs added to backend responses (would 404 silently with ATS now enforced)
- [ ] Firebase API keys restricted in Cloud Console (§2.2)
- [ ] `flutter analyze` clean
- [ ] Release built with `--obfuscate --split-debug-info=…` (§2.4)
- [ ] Debug symbols archived per release
- [ ] No service account JSON, `.p8`, or keystore files in git
- [ ] Signing keystore stored offline + backed up
- [ ] APNs key still valid (Apple keys don't expire, but rotate if a developer leaves)
- [ ] Test logout fully clears auth + FCM token on a real device
- [ ] Test 401 auto-logout still works (revoke a token server-side and verify the app boots back to login)
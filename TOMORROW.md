# Plan for Tomorrow

**Goal:** Finish push notifications end-to-end + start security hardening.

---

## Morning (≈ 2 hr) — close out iOS push so you can do an end-to-end test

### 1. APNs key (15 min)
- [ ] Apple Developer → Keys → **+** → enable **Apple Push Notifications service (APNs)**
- [ ] Download `.p8` (only downloadable once — store it safely)
- [ ] Note the **Key ID** and **Team ID**
- [ ] Firebase Console → `maicafe` → Project Settings → **Cloud Messaging** → upload `.p8` to the iOS app config with Key ID + Team ID

### 2. Xcode capabilities (5 min)
- [ ] Open `ios/Runner.xcworkspace`
- [ ] Runner target → Signing & Capabilities → **+ Capability → Push Notifications**
- [ ] **+ Capability → Background Modes** → tick **Remote notifications**

### 3. Build & install on a real iPhone (30 min)
- [ ] `flutter clean && flutter pub get`
- [ ] `cd ios && pod install && cd ..`
- [ ] `flutter run --release` on a **physical device** (simulator can't receive APNs)
- [ ] Log in → confirm `POST /api/user/fcm-token` returns 200 in backend logs

### 4. Smoke-test foreground/background/terminated states (45 min)
*Requires backend endpoints from step 5.*
- [ ] Foreground push → banner appears
- [ ] Background push tap → app opens to home
- [ ] Terminated push tap → app opens to home
- [ ] Order push with `data.order_id` → opens directly to that order's details screen

---

## Midday (≈ 30 min) — hand off to backend

### 5. Backend handoff
- [ ] Send `MaiCafe_Backend_Push_Notification_Guide.md` to the backend dev
- [ ] Download fresh **service account JSON** from Firebase Console → Service Accounts → Generate new private key
- [ ] Share JSON via 1Password / Signal / encrypted channel — **never email**
- [ ] Confirm they can run a basic test: register a token from the app, then send to that single token from `php artisan tinker`

---

## Afternoon (≈ 2.5 hr) — secure storage migration

*From `SECURITY.md` §2.1 — the only HIGH-severity audit finding.*

### 6. Migrate auth token to `flutter_secure_storage`
- [ ] Add `flutter_secure_storage: ^9.2.2` to `pubspec.yaml`
- [ ] In `lib/core/services/storage_service.dart`:
  - Load `authToken` + `tokenType` into in-memory cache at `init()` (keeps `ApiService._authHeaders` synchronous — no cascade refactor)
  - Write-through to secure storage on save/clear
- [ ] Move sensitive keys to secure storage: `authToken`, `tokenType`, `refreshToken`
- [ ] Keep non-sensitive keys in `SharedPreferences`: theme, language, cached menu, address cache, cart, etc.
- [ ] Test: login → hot-restart → confirm still authenticated
- [ ] Test: logout → confirm token gone from Keychain (`security find-generic-password -a <user> -s <service>` on macOS)

> If Claude is driving: ~30 min. Solo: ~2.5 hr including testing.

---

## Late afternoon (≈ 1 hr) — Firebase Console hardening + obfuscated release build

### 7. Restrict Firebase API keys (15 min)
*From `SECURITY.md` §2.2.*
- [ ] Get release SHA-1: `cd android && ./gradlew :app:signingReport`
- [ ] Google Cloud Console → APIs & Services → Credentials, for project `maicafe-552cd`:
  - Android key → restrict to package `com.maicafe.mc_cafe_app` + release SHA-1 + debug SHA-1
  - iOS key → restrict to bundle ID `com.maicafe.mcCafeApp`
  - API restrictions → restrict each key to Cloud Messaging + Identity Toolkit (whichever you use)

### 8. Build with obfuscation (30 min)
*From `SECURITY.md` §2.4.*
- [ ] Android:
  ```
  flutter build appbundle --release --obfuscate --split-debug-info=./build/debug-symbols
  ```
- [ ] iOS (if shipping this week):
  ```
  flutter build ipa --release --obfuscate --split-debug-info=./build/debug-symbols
  ```
- [ ] **Archive the `debug-symbols/` directory** before uploading — you'll need it to symbolicate Crashlytics / Sentry stack traces later

---

## End of day (15 min) — queue tomorrow's tomorrow

### 9. Review `STORE_SUBMISSION_CHECKLIST.md`
- [ ] Open the file (currently untracked in git status)
- [ ] Note what else is blocking store submission
- [ ] Decide what goes on the next day's plan

---

## What you need ready by 9am

- Apple Developer account access (for APNs key creation)
- A **physical iPhone** signed into your dev account
- Backend developer contact + a secure channel for the service account JSON
- Release keystore on hand for the `signingReport` SHA-1 lookup

## Probable blockers

- **Backend endpoints not yet live** → step 4 slips to whenever they're up. Steps 6, 7, 8 are independent and can fill that gap.
- **APNs key already exists for the team** → check Apple Developer Keys list before creating a new one (Apple caps at 2 keys per team).
- **`pod install` hangs** on first run after Firebase install → re-run with `pod install --repo-update`.

---

## Definition of done for the day

- [ ] An admin-panel-sent test push lands on a real iPhone in all three app states
- [ ] Auth token no longer in plaintext SharedPreferences
- [ ] Firebase API keys restricted in Cloud Console
- [ ] Obfuscated release AAB built and archived with its debug symbols
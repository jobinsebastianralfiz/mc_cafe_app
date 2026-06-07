# MAICAFE — Deployment Guide

Reference for publishing the MAICAFE app to **Google Play Store** and **Apple App Store**.

---

## 0. App Identity (already configured)

| Field | Value |
|---|---|
| App display name | `MAICAFE` |
| Android package | `com.maicafe.mc_cafe_app` |
| iOS bundle ID | `com.maicafe.mcCafeApp` |
| Firebase project | `maicafe-552cd` |
| Firebase project number | `355340288168` |
| Backend API | `https://maicafeuk.com/api` |
| Currency | GBP (£) |
| Support email | `info@maicafe.co.uk` |
| Support phone | `+447939256855` |
| Privacy policy | `https://maicafe.co.uk/privacy/` |
| Terms of service | `https://maicafe.co.uk/terms-of-service/` |

---

# 🤖 ANDROID — Google Play Store

## 1. Critical files & secrets (DO NOT LOSE)

| Item | Location |
|---|---|
| Upload keystore | `/Users/jobinsebastian/maicafe-upload-keystore.jks` |
| Keystore alias | `maicfeupload` |
| Validity | until **22 Sept 2053** |
| Signing config (gitignored) | `android/key.properties` |
| Firebase config | `android/app/google-services.json` |

### Upload key SHA fingerprints
```
SHA-1:   08:67:73:6F:40:1B:5E:0B:27:52:F9:A0:F4:27:F1:68:20:42:2F:11
SHA-256: 85:7A:58:E4:F3:C3:2D:A0:A6:1B:71:CE:18:D2:AA:D1:06:7E:4C:7C:1F:13:62:E4:38:AC:5E:5D:41:E0:5A:97
```

Re-print anytime:
```bash
keytool -list -v -keystore ~/maicafe-upload-keystore.jks -alias maicfeupload
```

### 🔐 Backup checklist (do this before anything else)

- [ ] Copy `maicafe-upload-keystore.jks` to a password manager / encrypted backup
- [ ] Save keystore password in password manager
- [ ] Save key alias `maicfeupload` in password manager
- [ ] **NEVER** commit `key.properties` or `*.jks` to git (already gitignored)

If you lose any of the three above, you can never publish updates to this Play Store listing.

---

## 2. Build the release AAB

```bash
cd /Users/jobinsebastian/StudioProjects/mc_cafe_app
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab` (~48 MB)

Verify it's signed with the release key (not the debug key):
```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```
Owner should read: `CN=Maicafe, OU=Maicafe, O=Maicafe, L=London, ST=London, C=GB`

---

## 3. Play Console listing requirements

Before you can publish, prepare these in **Play Console → your app**:

### Listing assets
- [ ] **App icon** — 512×512 PNG
- [ ] **Feature graphic** — 1024×500 PNG/JPG
- [ ] **Phone screenshots** — at least 2, max 8 (16:9 or 9:16; min 320 px, max 3840 px)
- [ ] **Tablet screenshots** (optional but recommended for 7" and 10")
- [ ] **Short description** — max 80 characters
- [ ] **Full description** — max 4000 characters
- [ ] **App category** — Food & Drink

### Compliance
- [ ] **Privacy policy URL** — `https://maicafe.co.uk/privacy/`
- [ ] **Content rating questionnaire** — complete the IARC questionnaire
- [ ] **Target audience and content** — set age range
- [ ] **Data safety form** — declare what data is collected:
  - Name (account info)
  - Email address (account info)
  - Phone number (account info)
  - Physical address (delivery)
  - Payment info (purchases — handled by API/payment gateway)
  - App activity (orders, cart, wishlist)
  - Device IDs (FCM token)
  - Photos (cached product images)
- [ ] **Ads declaration** — declare app does not contain ads (unless it does)
- [ ] **Government apps** — N/A
- [ ] **News apps** — N/A
- [ ] **Health apps** — N/A
- [ ] **Financial features** — declare in-app purchases / payment processing if applicable

### Pricing & distribution
- [ ] Free or paid (likely Free)
- [ ] Countries — select UK at minimum, plus any others you ship to
- [ ] Device categories — Phone, Tablet
- [ ] Required Play services

---

## 4. Upload AAB → enable Play App Signing

1. Open Play Console → your app → **Production** (or **Internal testing** for first run)
2. Click **Create new release**
3. Upload `build/app/outputs/bundle/release/app-release.aab`
4. **Enable Play App Signing** when prompted (default — recommended)
5. Add release notes
6. Save → Review release → **Roll out to internal testing**

**Recommended flow for first release:**
Internal testing → Closed testing (alpha) → Open testing (beta) → Production

---

## 5. ⚠️ Post-upload: register Play App Signing key in Firebase

This step is **easy to forget** but crucial. After Play App Signing is enabled, Google re-signs your AAB with their own key. FCM/Firebase Auth verify against **Google's signing key**, not your upload key.

1. Play Console → your app → **Setup → App signing** (left sidebar)
2. You'll see two certificates:
   - **App signing key certificate** ← Google's key (this is what users actually verify against)
   - **Upload key certificate** ← your `maicfeupload` key
3. Copy **SHA-1** AND **SHA-256** from "**App signing key certificate**" section
4. Open Firebase Console → Project settings → Your Android app
5. Click **Add fingerprint** twice — paste both
6. Re-download `google-services.json`
7. **Diff against existing** — see below
8. Only rebuild & re-upload AAB **if** the JSON actually changed

After this, FCM push notifications work for **all** users, including Play-Store-installed builds.

### 🛑 Do NOT delete the existing upload-key SHAs

Keep **both sets** of fingerprints in Firebase. After this step you should have **4 entries total**:

| | SHA-1 | SHA-256 | Used when |
|---|---|---|---|
| **Upload key** (`maicfeupload`) | `08:67:73:6F:40:1B:5E:0B:27:52:F9:A0:F4:27:F1:68:20:42:2F:11` | `85:7A:58:E4:F3:C3:2D:A0:A6:1B:71:CE:18:D2:AA:D1:06:7E:4C:7C:1F:13:62:E4:38:AC:5E:5D:41:E0:5A:97` | Local release builds, internal/sideloaded testing |
| **App Signing key** (Google's) | (from Play Console) | (from Play Console) | Play Store-installed builds (Google re-signs the AAB) |

A single app runs with **either signature** depending on how it was installed — Firebase needs to recognize both. **Add, never delete.** Firebase has no upper limit on fingerprints.

### When to actually rebuild & re-upload

```bash
# After downloading the new google-services.json:
diff ~/Downloads/google-services.json android/app/google-services.json
```

- **No output** (files identical) → SHAs are registered server-side at Firebase, no rebuild needed. Done.
- **Diff shows changes** → replace the file, bump version in `pubspec.yaml`, rebuild AAB, re-upload to Play Console.

For an FCM-only setup (no Google Sign-In / no OAuth client configured), the JSON usually does **not** change when SHAs are added — so the rebuild step is typically skipped. The SHAs are still doing real work because they're stored on Firebase's servers, not just in the JSON.

---

## 6. Future Android releases

For every subsequent release, bump the version in `pubspec.yaml`:
```yaml
version: 1.0.1+2   # was 1.0.0+1
#         ^^^^^ ^
#         |     +-- versionCode (must increment for every Play upload)
#         +-- versionName (user-facing, semver)
```

Then rebuild and upload:
```bash
flutter build appbundle --release
```

Play Console rejects uploads where `versionCode` ≤ the highest already uploaded.

---

# 🍎 iOS — Apple App Store

## 1. Prerequisites

- [ ] **Apple Developer Program** membership ($99/year) — https://developer.apple.com/programs/
- [ ] **App Store Connect** account access — https://appstoreconnect.apple.com
- [ ] **Mac with Xcode** (latest stable version)
- [ ] **iPhone for testing** (signed in with same Apple ID)

---

## 2. Register the app in Apple Developer / App Store Connect

### a) Register App ID
1. https://developer.apple.com/account/resources/identifiers/list
2. Click **+** → **App IDs** → **App** → Continue
3. **Bundle ID**: `com.maicafe.mcCafeApp` (must match the iOS bundle exactly)
4. Enable capabilities:
   - [ ] **Push Notifications**
   - [ ] **Background Modes** (for FCM background handler)
5. Continue → Register

### b) Create app in App Store Connect
1. https://appstoreconnect.apple.com → My Apps → **+** → New App
2. **Platform**: iOS
3. **Bundle ID**: select `com.maicafe.mcCafeApp`
4. **Name**: `MAICAFE`
5. **Primary Language**: English (U.K.)
6. **SKU**: `maicafe-ios-001` (any unique string)
7. **User Access**: Full Access

---

## 3. Push Notifications setup (APNs + Firebase)

Without this, push notifications won't work on iOS even though FCM is wired up.

### a) Create APNs Authentication Key
1. https://developer.apple.com/account/resources/authkeys/list
2. Click **+** → name it `MAICAFE APNs Key` → enable **Apple Push Notifications service (APNs)** → Continue → Register
3. **Download the `.p8` file IMMEDIATELY** — Apple only lets you download it once
4. Note the **Key ID** (10 characters) shown on the page
5. Note your **Team ID** — found at https://developer.apple.com/account → top right

### b) Upload to Firebase
1. Firebase Console → Project settings → **Cloud Messaging** tab
2. Scroll to **Apple app configuration** → your iOS app
3. Under **APNs Authentication Key**, click **Upload**
4. Upload the `.p8` file, paste the Key ID and Team ID
5. Save

### c) Enable push capability in Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target → **Signing & Capabilities**
3. Click **+ Capability** → add:
   - [ ] **Push Notifications**
   - [ ] **Background Modes** → check `Remote notifications` and `Background fetch`

---

## 4. Code signing in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`)
2. Select **Runner** target → **Signing & Capabilities**
3. Check **Automatically manage signing**
4. Select your **Team** from the dropdown
5. **Bundle Identifier**: `com.maicafe.mcCafeApp` (already set)
6. Xcode generates a provisioning profile automatically

If you prefer manual signing, create:
- Distribution certificate at https://developer.apple.com/account/resources/certificates/list
- App Store provisioning profile at https://developer.apple.com/account/resources/profiles/list

---

## 5. Privacy manifests & info.plist

iOS requires usage descriptions for any tracked data and a privacy manifest as of 2024+.

### Check `ios/Runner/Info.plist` already has:
- [x] `NSAppTransportSecurity` → `NSAllowsArbitraryLoads = false` (already configured)
- [x] `CFBundleDisplayName = MAICAFE` (already configured)

### Add if not present (for any feature you use):
```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier is used to deliver personalised offers.</string>
<!-- Only add the above if you use ATT / advertising IDs -->
```

### Privacy manifest (`PrivacyInfo.xcprivacy`)
Apple requires `PrivacyInfo.xcprivacy` declaring:
- Required reason API usage (UserDefaults, file timestamps, etc.)
- Tracking domains
- Collected data types

Most Flutter plugins (`shared_preferences`, `firebase_*`, `flutter_local_notifications`) ship their own privacy manifests — your app's manifest only needs to cover any direct iOS API usage your custom code does. If you're not using ATT, this can stay minimal.

---

## 6. Build & archive iOS release

### Update version
Same `pubspec.yaml` `version: 1.0.0+1` is shared with iOS. Bump for each release.

### Build
```bash
cd /Users/jobinsebastian/StudioProjects/mc_cafe_app
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

This produces:
- `build/ios/archive/Runner.xcarchive` — Xcode archive
- `build/ios/ipa/MAICAFE.ipa` — distributable IPA

### Alternative: archive in Xcode
1. `open ios/Runner.xcworkspace`
2. Select **Any iOS Device (arm64)** as the run destination (top bar)
3. Menu → **Product → Archive**
4. When archiving completes, Xcode opens the **Organizer** window

---

## 7. Upload to App Store Connect

### Option A — from Xcode Organizer
1. After archiving, in the Organizer window: select the latest archive → **Distribute App**
2. **App Store Connect** → Next
3. **Upload** → Next
4. Accept signing options → Upload
5. Wait ~5–15 min for Apple to process the build

### Option B — Transporter app
1. Download **Transporter** from Mac App Store
2. Open Transporter → drag `build/ios/ipa/MAICAFE.ipa` in
3. Click **Deliver**

### Option C — command line
```bash
xcrun altool --upload-app -f build/ios/ipa/MAICAFE.ipa \
  -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD
```
(Generate app-specific password at https://appleid.apple.com)

---

## 8. App Store Connect listing requirements

Open https://appstoreconnect.apple.com → My Apps → MAICAFE.

### App Information
- [ ] **Subtitle** — max 30 characters (e.g. "A Taste Worth Savouring")
- [ ] **Category** — Primary: Food & Drink
- [ ] **Content rights** — declare if you have rights to all content
- [ ] **Age rating** — fill out the questionnaire

### Pricing and Availability
- [ ] **Price** — Free (or set price tier)
- [ ] **Availability** — countries (UK at minimum)

### App Privacy
- [ ] **Privacy policy URL** — `https://maicafe.co.uk/privacy/`
- [ ] **Privacy choices URL** (optional)
- [ ] **Data Types** — declare what's collected (similar to Play Console Data Safety):
  - Contact Info: Name, Email, Phone, Physical Address
  - Identifiers: User ID, Device ID (FCM token)
  - Purchases: Purchase History
  - Usage Data: Product Interaction
  - Diagnostics: Crash Data, Performance Data (if Firebase Crashlytics added)

### Version Information (per release)
- [ ] **Promotional text** — max 170 characters (can be updated without new build)
- [ ] **Description** — max 4000 characters
- [ ] **Keywords** — max 100 characters total, comma-separated
- [ ] **Support URL** — required (e.g. https://maicafe.co.uk/support)
- [ ] **Marketing URL** — optional
- [ ] **Version number** — matches pubspec version
- [ ] **Copyright** — e.g. `© 2026 Maicafe Ltd`
- [ ] **App Review Information** — sign-in credentials for the reviewer (test account)
- [ ] **What's New in This Version** — release notes (4000 char limit)

### Screenshots (required)
- [ ] **6.7" iPhone** (1290×2796 or 1284×2778) — min 3
- [ ] **6.5" iPhone** (1242×2688) — min 3
- [ ] **5.5" iPhone** (1242×2208) — min 3
- [ ] **iPad Pro 12.9" 2nd & 6th gen** (2048×2732) — if iPad supported, min 3
- [ ] **App Preview videos** — optional, 15–30 sec, .mov/.mp4

Tools like https://screenshots.pro or `screenshots-tool` can auto-generate these from a single source.

### Build
- [ ] Select the build you uploaded (appears under **Build** section after Apple processes it)

### Export Compliance
- [ ] Answer encryption questions — for HTTPS-only apps, the answer is usually "uses standard encryption, qualifies for exemption"

---

## 9. TestFlight (recommended before App Store submission)

After upload + Apple processing:
1. App Store Connect → MAICAFE → **TestFlight**
2. Build will appear under **iOS Builds**
3. Click the build → answer **Export Compliance** questions
4. Add **Internal Testers** (your team — up to 100, no review needed)
5. For external testers (up to 10,000): create a Group → submit for **Beta App Review** (~24h turnaround)
6. Testers install via TestFlight app on iPhone

---

## 10. Submit for App Store Review

When you're ready:
1. App Store Connect → MAICAFE → **App Store** tab
2. Fill all metadata, screenshots, etc. above
3. Select the build under **Build** section
4. Click **Add for Review** → **Submit for Review**
5. Status: **Waiting for Review** → **In Review** → **Approved** / **Rejected**

Typical Apple review time: 24–48 hours.

If rejected, Apple sends specific feedback in **App Store Connect → Resolution Center**. Common issues:
- Missing test account credentials for reviewer
- Bugs/crashes not reproducible by you
- Privacy policy doesn't mention all data collected
- Login wall before any user value shown (3.1.3 / 3.1.5)
- Use of private APIs

---

## 11. Future iOS releases

Same as Android: bump `version: 1.0.0+1` in `pubspec.yaml`, then:
```bash
flutter build ipa --release
```
Upload via Xcode Organizer or Transporter. Submit through App Store Connect.

iOS uses `CFBundleShortVersionString` (= versionName) and `CFBundleVersion` (= versionCode) — both are auto-pulled from pubspec.

---

# 📋 Pre-flight checklist (already done)

✅ App name `MAICAFE` consistent across Android, iOS, Flutter  
✅ Currency = GBP  
✅ Real support contact, privacy, terms URLs  
✅ Manifest permissions clean & justified  
✅ `usesCleartextTraffic="false"`  
✅ ATS configured (HTTPS only) on iOS  
✅ `debugShowCheckedModeBanner: false`  
✅ No `print()` / `debugPrint()` in `lib/`  
✅ Release keystore generated (`maicfeupload`, valid until 2053)  
✅ `key.properties` + `*.jks` gitignored  
✅ Release build signed with release key (verified)  
✅ FCM upload key SHAs registered in Firebase  
✅ Release AAB builds successfully (~48 MB)

---

# 📞 Quick reference

```bash
# Print keystore info
keytool -list -v -keystore ~/maicafe-upload-keystore.jks -alias maicfeupload

# Build Android release
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab

# Verify Android signing
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab

# Build iOS release
flutter build ipa --release
# → build/ios/ipa/MAICAFE.ipa

# Install release on connected device (sanity check)
flutter install --release
```
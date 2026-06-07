# MAICAFE — Play Store & App Store Submission Checklist

This document lists **everything we need to collect from the client** before we can upload MAICAFE to the Google Play Store and Apple App Store.

App facts (already set in the repo):
- **App name (display):** MAICAFE
- **Marketing tagline:** A Taste Worth Savouring
- **Android package / iOS Bundle ID:** `com.maicafe.mc_cafe_app`
- **Version:** `1.0.0+1` (from `pubspec.yaml`)
- **Primary category:** Food & Drink
- **Backend API:** `https://maicafeuk.com/api`
- **Storage/CDN:** `https://maicafeuk.com/storage`
- **Public website:** `https://maicafeuk.com`
- **Privacy Policy:** `https://maicafeuk.com/privacy-policy`
- **Terms & Conditions:** `https://maicafeuk.com/terms-and-conditions`

---

## 1. Identity & Ownership (needed first)

| Item | Why | Notes |
|---|---|---|
| Legal company / owner name | Appears on both store listings ("Seller") | Person or registered entity |
| Owner street address | Required by Apple + Google for paid / transactional apps | Full postal address |
| Support email | Public, monitored mailbox | e.g. `support@maicafe.com` |
| Support phone number | Optional for Google, required for App Review contact on Apple | |
| Public website URL | Goes on both listings | e.g. `https://maicafe.com` |
| Privacy Policy URL (public) | **Mandatory — both stores will reject without it** | e.g. `https://maicafe.com/privacy` |
| Terms of Service URL | Recommended | |
| Marketing URL (optional) | Apple only | |

---

## 2. Developer / Publisher Accounts

| Account | Cost | Who owns it | What we need from client |
|---|---|---|---|
| **Apple Developer Program** | USD 99 / yr | Client | Apple ID email, 2FA access, confirmation that the account is enrolled as Individual or Organization (if Org: D-U-N-S number) |
| **App Store Connect** | included | Client | Invite our Apple ID as Admin / App Manager |
| **Google Play Console** | USD 25 one-time | Client | Google account email, verified identity, invite our email as Admin |

---

## 3. Package Name / Bundle ID / Domain

| Platform | Value (already in repo) | Can be changed? |
|---|---|---|
| Android `applicationId` | `com.maicafe.mc_cafe_app` | Must be final before first upload — it can NEVER be changed once published |
| iOS `CFBundleIdentifier` | `com.maicafe.mc_cafe_app` (via Xcode target) | Same — final before first upload |
| Domain used in IDs | `maicafe.com` (reverse-DNS) | Confirm with client that they own `maicafe.com` |

> Action for client: confirm they own the `maicafe.com` domain, and confirm the final bundle ID. If they'd rather use `com.maicafe.app` or similar, decide **before** the first TestFlight / Internal Testing upload.

---

## 4. Signing Credentials (we will generate, but client must store backup)

### Android — Upload Keystore
- We will generate `upload-keystore.jks` locally.
- **Client must receive & securely back up:**
  - The `.jks` file
  - Keystore password
  - Key alias (`upload`)
  - Key password
- Losing this = cannot push updates. Ever.

### iOS — Certificates & Profiles
- Generated automatically from the client's Apple Developer account.
- Client keeps ownership of the team; we just need Admin invite.

---

## 5. Store Listing Copy (content)

The client should provide final copy for these fields. We can draft, but they must approve.

### Shared
- **App name** — max 30 chars (Play) / 30 chars (Apple). Proposed: `MAICAFE`
- **Subtitle / Short description** — max 30 chars (Apple) / 80 chars (Play). Proposed: `A Taste Worth Savouring`
- **Full description** — up to 4000 chars. **Needs writing.**
- **What's New / Release notes** — per release
- **Keywords** (Apple only) — comma-separated, 100 chars total
- **Promotional text** (Apple only) — 170 chars, editable without resubmit

### Categorisation
- Primary category: Food & Drink
- Secondary category (Apple, optional): Lifestyle
- Content rating questionnaire answers (both stores)
- Target audience / age band (Play Store)

---

## 6. Visual Assets

### Icon (already in repo: `assets/images/app_icon.png`)
Regenerated per-platform via `flutter_launcher_icons`. If client wants a different icon, they must provide:
- **1024 × 1024 px** PNG, no transparency, no rounded corners (Apple strips them)
- Same source image also used for Play Store high-res icon: **512 × 512 px** PNG, 32-bit

### Splash (already in repo: `assets/images/splash_icon.png`, bg `#D4A574`)
If client wants a different splash: same PNG sources with transparent bg.

### Logo (already in repo: `assets/logos/mc_logo.png`)
Confirm this is the final logo.

### Screenshots — **CLIENT TO REVIEW / APPROVE**
We will capture these from a real device. Required sizes:

**iOS (minimum 3, maximum 10 per size):**
| Device | Pixel size |
|---|---|
| iPhone 6.9" / 6.7" | 1290 × 2796 |
| iPhone 6.5" | 1242 × 2688 |
| iPhone 5.5" | 1242 × 2208 |
| iPad Pro 12.9" (if supporting iPad) | 2048 × 2732 |

**Android (minimum 2, maximum 8):**
| Asset | Size |
|---|---|
| Phone screenshots | 1080 × 1920 (portrait) or higher, 16:9 / 9:16 |
| 7" tablet screenshots (recommended) | 1024 × 600+ |
| 10" tablet screenshots (recommended) | 1920 × 1200+ |
| **Feature graphic (REQUIRED)** | **1024 × 500 PNG/JPG** |

### Optional promo video
- 15–30 s YouTube link. Not required. Ask client if they have one.

---

## 7. Data Collection Disclosure

Both stores make us declare what the app collects. Based on the current codebase the app collects:

| Data type | Collected? | Purpose | Shared with 3rd parties? |
|---|---|---|---|
| Name | Yes | Account, orders | Confirm with client |
| Email | Yes | Account, login, OTP | Confirm |
| Phone number | Yes | Orders / delivery | Confirm |
| Password (hashed) | Yes | Authentication | No |
| Delivery address | Yes | Order fulfilment | Delivery partner? (client to confirm) |
| Order history / purchases | Yes | Order tracking | Backend only |
| Device identifiers | Yes (implicit) | Session / auth token | No |
| Location (GPS) | **No** — not currently requested | — | — |
| Payment / card details | **Handled by payment processor, not stored in-app** | Confirm with client which processor (Shift4 per `shift4-payment-integration-plan.md`) |
| Analytics / crash tools | None currently wired in | If client wants Firebase / Crashlytics → must redeclare |
| Advertising ID | No ads in app | — |

> **We need the client to confirm** every row above, plus:
> - Whether the backend shares any of it with third parties (delivery, SMS gateway, payment)
> - Retention policy (how long after account deletion)

---

## 8. Account Deletion Flow (blocking requirement)

- Google Play has required **in-app account deletion** since 2023; Apple requires it for any app with account creation.
- The UI button exists in `profile_screen.dart` but currently only shows a snackbar (see `DEPLOYMENT_GUIDE.txt`).
- **Need from client:** confirmation that `DELETE /user/account` is implemented on the backend (endpoint `/user/account` is already referenced in `api_config.dart`), and what exactly gets deleted vs. retained for legal/accounting reasons.

---

## 9. Apple-Specific

| Item | Need from client |
|---|---|
| Apple Developer Team ID | Yes (10-char ID) |
| App Store Connect App SKU | Proposed: `maicafe-ios-001` — confirm |
| Export Compliance | App uses HTTPS only → qualifies for exemption. Client confirms no custom cryptography. |
| Demo / test account credentials | Reviewers must be able to log in — email + password for a test account on the production backend |
| Third-party login (Google / Facebook / Apple) | Currently none. If added later, **must** add Sign in with Apple. |
| iPad support? | Currently universal (Info.plist allows iPad orientations). Confirm client wants iPad listing. |

---

## 10. Google-Specific

| Item | Need from client |
|---|---|
| Play Console app access credentials for review | Test account email + password |
| Target countries | Default: worldwide. Confirm any exclusions. |
| Pricing | Free (confirm) |
| Ads declaration | No ads (confirm) |
| Government app? | No |
| News app? | No |
| COVID-19 app? | No |
| Families / children policy | Not targeting children → confirm |
| Financial features declaration | Only if app does in-app purchases of digital goods (food orders are physical goods → not IAP) |

---

## 11. Payments

The repo contains `shift4-payment-integration-plan.md` and card-input widgets under `lib/widgets/card_number_input_form`. Before submission, confirm:

- Is payment live in v1, or stubbed?
- Which processor? (Shift4 per the plan file)
- **Apple rule:** physical goods paid via card processor → fine. Digital goods → must use Apple IAP. Food delivery = physical → OK.
- PCI scope: card data must not be stored on device or our backend; it goes directly to the processor. Confirm integration uses hosted fields / tokenisation.

---

## 12. Permissions Declared (Android)

Already in `AndroidManifest.xml`:
- `INTERNET`, `ACCESS_NETWORK_STATE` — API calls
- `VIBRATE`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` — local order-status notifications

No runtime-dangerous permissions beyond notifications. Nothing to justify to Play review beyond the notification prompt.

iOS Info.plist currently has `NSAllowsArbitraryLoads=true` under ATS — **should be removed or tightened before release** since the backend serves HTTPS (`https://maicafeuk.com`). Apple reviewers often flag arbitrary-loads without justification.

---

## 13. Pre-Submission Technical Checklist (our side)

- [ ] Lock final `applicationId` / Bundle ID with client
- [ ] Generate Android upload keystore; share secure backup with client
- [ ] Configure `android/key.properties` + release signing in `build.gradle.kts` (TODO in repo)
- [ ] Bump `version:` in `pubspec.yaml` for each build
- [ ] Remove `NSAllowsArbitraryLoads` from `ios/Runner/Info.plist`
- [ ] Implement real account deletion call (wire to `/user/account`)
- [ ] Generate icons: `dart run flutter_launcher_icons`
- [ ] Generate splash: `dart run flutter_native_splash:create`
- [ ] `flutter build appbundle --release` → `app-release.aab`
- [ ] `flutter build ios --release` → archive & upload via Xcode Organizer
- [ ] Capture final screenshots on required device sizes
- [ ] Fill Data Safety (Play) + Privacy Nutrition Label (Apple)
- [ ] Submit to Internal Testing / TestFlight first; production after sign-off

---

## Summary — One-page "please send us" list for the client

1. Legal business name + address
2. Support email, support phone, website URL
3. **Privacy Policy URL** (hosted, public)
4. Terms of Service URL (recommended)
5. Confirmation of domain ownership: `maicafe.com`
6. Confirmation of final bundle ID: `com.maicafe.mc_cafe_app`
7. Apple Developer Program enrolment + invite to our Apple ID as Admin
8. Google Play Console account + invite to our Google account as Admin
9. Final app icon (1024×1024) and logo — or confirmation to use what's in the repo
10. Final short description, full description, keywords
11. Test account credentials (email + password) for store reviewers
12. Confirmation of data-collection answers in §7
13. Confirmation that backend `DELETE /user/account` is implemented
14. Payment processor confirmation (Shift4 live in v1? yes/no)
15. Target countries for release + free/paid decision

Once all of the above is in hand, we can ship the first TestFlight build and first Play Console Internal Testing release the same day.

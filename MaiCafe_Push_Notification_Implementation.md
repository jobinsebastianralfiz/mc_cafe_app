



# MaiCafe — Push Notification Implementation Guide (Flutter)

**Version:** 1.0  
**Date:** April 2026  
**Backend:** Laravel (maicafeuk.com)  
**Mobile:** Flutter  

---

## Table of Contents

1. [Overview](#1-overview)
2. [Firebase Project Setup](#2-firebase-project-setup)
3. [Flutter Package Installation](#3-flutter-package-installation)
4. [Android Setup](#4-android-setup)
5. [iOS Setup](#5-ios-setup)
6. [Flutter Code Implementation](#6-flutter-code-implementation)
7. [API Integration with MaiCafe Backend](#7-api-integration-with-maicafe-backend)
8. [Handling Notification Taps](#8-handling-notification-taps)
9. [Full Example — NotificationService](#9-full-example--notificationservice)
10. [Testing](#10-testing)

---

## 1. Overview

When a user installs the MaiCafe app, the device is assigned a unique **FCM token** by Firebase. This token is saved to the MaiCafe server so the admin can send push notifications to all users or specific groups directly from the Admin Panel.

```
Flutter App                   MaiCafe Backend              Firebase (FCM)
    │                               │                            │
    │── Login ──────────────────────▶                            │
    │◀─ Auth Token ─────────────────│                            │
    │                               │                            │
    │── Get FCM Token (Firebase) ──▶ Firebase SDK                │
    │◀─ FCM Token ──────────────────│                            │
    │                               │                            │
    │── POST /api/user/fcm-token ──▶│                            │
    │   { fcm_token: "xxx" }        │                            │
    │                               │                            │
    │                         Admin sends                        │
    │                         notification ──────────────────────▶
    │◀────────────────────────────────── Push Notification ──────│
```

---

## 2. Firebase Project Setup

### Step 1 — Create a Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add Project** → Name it `maicafe` → Continue
3. Disable Google Analytics if not needed → **Create Project**

### Step 2 — Add Android App

1. Click the **Android icon** in the Firebase console
2. Enter your Android package name (e.g. `com.maicafe.app`)
3. Download the `google-services.json` file
4. Place it in `android/app/google-services.json`

### Step 3 — Add iOS App

1. Click the **iOS icon** in the Firebase console
2. Enter your iOS bundle ID (e.g. `com.maicafe.app`)
3. Download the `GoogleService-Info.plist` file
4. Open Xcode → drag `GoogleService-Info.plist` into `Runner/` folder
5. Make sure **Copy items if needed** is checked

### Step 4 — Get the Service Account JSON (for Admin Panel)

1. In Firebase Console → **Project Settings** (gear icon)
2. Go to **Service Accounts** tab
3. Click **Generate New Private Key** → Download JSON
4. Go to **MaiCafe Admin Panel** → **Notifications** → paste the JSON → Save

---

## 3. Flutter Package Installation

Add these packages to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^17.0.0
```

Then run:

```bash
flutter pub get
```

---

## 4. Android Setup

### `android/build.gradle`

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.1'
    }
}
```

### `android/app/build.gradle`

```gradle
apply plugin: 'com.android.application'
// Add this line at the bottom
apply plugin: 'com.google.gms.google-services'

android {
    // ...
}

dependencies {
    // ...
}
```

### `android/app/src/main/AndroidManifest.xml`

Add these inside the `<application>` tag:

```xml
<!-- FCM Default Notification Channel (Android 8+) -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="maicafe_notifications" />

<!-- Notification icon and color -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
```

Create `android/app/src/main/res/values/colors.xml` if it doesn't exist:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#f97316</color>
</resources>
```

---

## 5. iOS Setup

### Enable Push Notifications Capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target → **Signing & Capabilities**
3. Click **+ Capability** → Add **Push Notifications**
4. Also add **Background Modes** → check **Remote notifications**

### Upload APNs Key to Firebase

1. Apple Developer Console → **Certificates, Identifiers & Profiles** → **Keys**
2. Create a new key → enable **Apple Push Notifications service (APNs)**
3. Download the `.p8` file
4. Firebase Console → **Project Settings** → **Cloud Messaging** → **Apple app configuration**
5. Upload the `.p8` file with your Key ID and Team ID

### `ios/Runner/AppDelegate.swift`

```swift
import UIKit
import Flutter
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

---

## 6. Flutter Code Implementation

### Initialize Firebase in `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    NotificationService.showLocalNotification(message);
}

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    runApp(const MyApp());
}
```

---

## 7. API Integration with MaiCafe Backend

### API Endpoints

| Method   | Endpoint               | Auth Required | Description                     |
|----------|------------------------|---------------|---------------------------------|
| `POST`   | `/api/user/fcm-token`  | Yes (Sanctum) | Register/update device FCM token |
| `DELETE` | `/api/user/fcm-token`  | Yes (Sanctum) | Clear token on logout            |

### Register Token After Login

Call this immediately after the user logs in and receives their auth token:

```dart
Future<void> registerFcmToken(String authToken) async {
    try {
        // Get FCM token from Firebase
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken == null) return;

        // Send to MaiCafe backend
        final response = await http.post(
            Uri.parse('https://maicafeuk.com/api/user/fcm-token'),
            headers: {
                'Authorization': 'Bearer $authToken',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode({'fcm_token': fcmToken}),
        );

        if (response.statusCode == 200) {
            debugPrint('FCM token registered successfully');
        }
    } catch (e) {
        debugPrint('Failed to register FCM token: $e');
    }
}
```

### Clear Token on Logout

```dart
Future<void> clearFcmToken(String authToken) async {
    try {
        await http.delete(
            Uri.parse('https://maicafeuk.com/api/user/fcm-token'),
            headers: {
                'Authorization': 'Bearer $authToken',
                'Accept': 'application/json',
            },
        );
    } catch (e) {
        debugPrint('Failed to clear FCM token: $e');
    }
}
```

### Handle Token Refresh

FCM tokens can change. Listen for token refreshes and re-register:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final authToken = await getStoredAuthToken(); // your local storage
    if (authToken != null) {
        await registerFcmToken(authToken);
    }
});
```

---

## 8. Handling Notification Taps

Notifications arrive in three app states:

| State          | Description                              | Handler                          |
|----------------|------------------------------------------|----------------------------------|
| **Foreground** | App is open and visible                  | `FirebaseMessaging.onMessage`    |
| **Background** | App is open but minimized                | `FirebaseMessaging.onMessageOpenedApp` |
| **Terminated** | App is fully closed                      | `FirebaseMessaging.instance.getInitialMessage()` |

```dart
void setupNotificationHandlers(BuildContext context) {
    // Foreground — show a local notification banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        NotificationService.showLocalNotification(message);
    });

    // Background — app was in background and user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(context, message);
    });

    // Terminated — app was closed and user tapped notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
            _handleNotificationTap(context, message);
        }
    });
}

void _handleNotificationTap(BuildContext context, RemoteMessage message) {
    final type = message.data['type'];
    // Navigate based on notification type
    if (type == 'broadcast') {
        // General admin notification — no specific navigation needed
        return;
    }
    // Add more types as needed
}
```

---

## 9. Full Example — NotificationService

Create `lib/services/notification_service.dart`:

```dart
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
    static final FlutterLocalNotificationsPlugin _localNotifications =
        FlutterLocalNotificationsPlugin();

    static const _channelId   = 'maicafe_notifications';
    static const _channelName = 'MaiCafe Notifications';
    static const _baseUrl     = 'https://maicafeuk.com/api';

    static Future<void> initialize() async {
        // Request permission
        final settings = await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
        );

        debugPrint('Notification permission: ${settings.authorizationStatus}');

        // Setup local notifications (for foreground display)
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
        );

        await _localNotifications.initialize(
            const InitializationSettings(
                android: androidSettings,
                iOS: iosSettings,
            ),
        );

        // Create Android notification channel
        const channel = AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'MaiCafe promotional and informational notifications',
            importance: Importance.high,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        // Set foreground presentation options for iOS
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
        );
    }

    static void showLocalNotification(RemoteMessage message) {
        final notification = message.notification;
        if (notification == null) return;

        _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
                android: AndroidNotificationDetails(
                    _channelId,
                    _channelName,
                    icon: '@mipmap/ic_launcher',
                    importance: Importance.high,
                    priority: Priority.high,
                    color: const Color(0xFFF97316),
                ),
                iOS: const DarwinNotificationDetails(
                    presentAlert: true,
                    presentBadge: true,
                    presentSound: true,
                ),
            ),
        );
    }

    static Future<void> registerToken(String authToken) async {
        try {
            final fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken == null) return;

            await http.post(
                Uri.parse('$_baseUrl/user/fcm-token'),
                headers: {
                    'Authorization': 'Bearer $authToken',
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                body: jsonEncode({'fcm_token': fcmToken}),
            );

            // Listen for token refresh
            FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
                await http.post(
                    Uri.parse('$_baseUrl/user/fcm-token'),
                    headers: {
                        'Authorization': 'Bearer $authToken',
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                    },
                    body: jsonEncode({'fcm_token': newToken}),
                );
            });
        } catch (e) {
            debugPrint('FCM registration error: $e');
        }
    }

    static Future<void> clearToken(String authToken) async {
        try {
            await http.delete(
                Uri.parse('$_baseUrl/user/fcm-token'),
                headers: {
                    'Authorization': 'Bearer $authToken',
                    'Accept': 'application/json',
                },
            );
            await FirebaseMessaging.instance.deleteToken();
        } catch (e) {
            debugPrint('FCM clear error: $e');
        }
    }
}
```

### Where to Call Each Method

```dart
// 1. On app start — in main.dart or splash screen
await NotificationService.initialize();

// 2. After successful login
final loginResponse = await loginUser(email, password);
await NotificationService.registerToken(loginResponse['token']);

// 3. On logout
await NotificationService.clearToken(storedAuthToken);
await logoutUser();

// 4. In your home screen initState — set up tap handlers
NotificationService.setupHandlers(context);
```

---

## 10. Testing

### Test 1 — Check Token is Registered

After logging in, check the MaiCafe admin panel:

1. Go to **Admin Panel → Notifications**
2. The **"devices registered"** count in the top right should increase

Or check the database:
```sql
SELECT name, email, fcm_token FROM users WHERE fcm_token IS NOT NULL;
```

### Test 2 — Send a Test Notification

1. Admin Panel → **Notifications**
2. Configure Firebase (paste service account JSON) if not done
3. Fill in Title: `Test`, Message: `Hello from MaiCafe!`
4. Audience: **All Users**
5. Click **Send Notification**
6. The notification should appear on the device

### Test 3 — Background Notification

1. Minimize the app
2. Send notification from admin panel
3. Notification banner should appear in the system tray
4. Tapping it should open the app

### Test 4 — Terminated App

1. Fully close the app (swipe away from recents)
2. Send notification from admin panel
3. Notification should appear
4. Tapping it should open the app

---

## Summary Checklist

- [ ] Firebase project created
- [ ] `google-services.json` added to `android/app/`
- [ ] `GoogleService-Info.plist` added to `ios/Runner/`
- [ ] APNs key uploaded to Firebase (iOS)
- [ ] Flutter packages installed (`firebase_core`, `firebase_messaging`, `flutter_local_notifications`)
- [ ] `NotificationService` class created
- [ ] `initialize()` called on app start
- [ ] `registerToken()` called after login
- [ ] `clearToken()` called on logout
- [ ] Background handler registered in `main.dart`
- [ ] Firebase service account JSON saved in Admin Panel → Notifications

---

## API Reference

**Base URL:** `https://maicafeuk.com/api`

### POST `/user/fcm-token`
Register or update the device FCM token.

**Headers:**
```
Authorization: Bearer {sanctum_token}
Content-Type: application/json
Accept: application/json
```

**Body:**
```json
{
    "fcm_token": "dGhpcyBpcyBhIHNhbXBsZSB0b2tlbg..."
}
```

**Response:**
```json
{
    "message": "FCM token updated successfully."
}
```

---

### DELETE `/user/fcm-token`
Clear the FCM token when user logs out (stops notifications to this device).

**Headers:**
```
Authorization: Bearer {sanctum_token}
Accept: application/json
```

**Response:**
```json
{
    "message": "FCM token cleared."
}
```

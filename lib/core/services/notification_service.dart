import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/models/notification_model.dart';
import '../../main.dart';
import '../../routes/app_routes.dart';
import '../config/api_config.dart';
import '../config/storage_keys.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Notification Service
///
/// Combines local notifications (flutter_local_notifications) with Firebase
/// Cloud Messaging (FCM) for remote push notifications. FCM messages received
/// while the app is in the foreground are re-displayed via a local
/// notification so banners always appear consistently.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  // Channels
  static const String _orderChannelId = 'mc_cafe_orders';
  static const String _orderChannelName = 'Order Updates';
  static const String _orderChannelDesc =
      'Notifications for order status updates';

  static const String _generalChannelId = 'maicafe_notifications';
  static const String _generalChannelName = 'MaiCafe Notifications';
  static const String _generalChannelDesc =
      'MaiCafe promotional and informational notifications';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _fcmInitialized = false;
  bool _permissionGranted = false;

  /// Initialize the local notification side of the service.
  ///
  /// Safe to call multiple times. FCM is initialized separately via [initFcm]
  /// so the local UI can be ready before any network/Firebase work happens.
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request separately
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      _isInitialized = true;

      // Check if app was launched from a local notification tap
      _checkInitialNotification();
    } catch (e) {
      // Initialization failed
    }
  }

  /// Initialize Firebase Cloud Messaging.
  ///
  /// Sets up permission, foreground presentation, message handlers, token
  /// refresh and routes incoming push notifications through the local
  /// notification channel so they always render consistently.
  Future<void> initFcm() async {
    if (_fcmInitialized) return;

    try {
      // Make sure local notifications are ready first.
      if (!_isInitialized) {
        await init();
      }

      final messaging = FirebaseMessaging.instance;

      // Ask for notification permission (no-op on platforms that grant by default).
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      // iOS: show alert/badge/sound for foreground messages.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground messages → render through local notifications plugin.
      FirebaseMessaging.onMessage.listen(_showRemoteAsLocal);

      // Background/Terminated taps that opened the app.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteTap);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        // Delay so the navigator is ready.
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleRemoteTap(initialMessage);
        });
      }

      // Token refresh: re-register with backend if user is logged in.
      messaging.onTokenRefresh.listen((newToken) async {
        await StorageService.instance.setString(StorageKeys.fcmToken, newToken);
        if (StorageService.instance.isLoggedIn) {
          await _postFcmToken(newToken);
        }
      });

      _fcmInitialized = true;
    } catch (_) {
      // FCM init failed — push notifications will be unavailable.
    }
  }

  /// Register the device's FCM token with the MaiCafe backend.
  ///
  /// Call this after a successful login / OTP verification, and on app start
  /// when the user is already authenticated. Safe to call repeatedly — the
  /// backend just upserts.
  Future<void> registerFcmToken() async {
    try {
      // Make sure FCM is up before asking for the token.
      if (!_fcmInitialized) {
        await initFcm();
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await StorageService.instance.setString(StorageKeys.fcmToken, token);
      await _postFcmToken(token);
    } catch (_) {
      // Token register failed — backend will retry on next launch / refresh.
    }
  }

  /// Clear the FCM token on the backend (used on logout).
  ///
  /// Must be called *before* clearing local auth, since the request needs the
  /// auth token in storage.
  Future<void> clearFcmToken() async {
    try {
      await ApiService.instance.delete(ApiConfig.fcmToken);
    } catch (_) {
      // Non-fatal — backend will eventually expire stale tokens.
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Non-fatal — token will be regenerated on next session.
    }

    await StorageService.instance.remove(StorageKeys.fcmToken);
  }

  Future<void> _postFcmToken(String token) async {
    await ApiService.instance.post(
      ApiConfig.fcmToken,
      body: {'fcm_token': token},
    );
  }

  /// Render a foreground RemoteMessage as a local notification.
  Future<void> _showRemoteAsLocal(RemoteMessage message) async {
    final notification = message.notification;

    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;

    // No display content — silent data-only message, ignore.
    if ((title == null || title.isEmpty) &&
        (body == null || body.isEmpty)) {
      return;
    }

    // Pick channel based on payload type.
    final type = message.data['type'] as String?;
    final isOrder = type == 'order' || message.data.containsKey('order_id');
    final channelId = isOrder ? _orderChannelId : _generalChannelId;
    final channelName = isOrder ? _orderChannelName : _generalChannelName;
    final channelDesc = isOrder ? _orderChannelDesc : _generalChannelDesc;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      channelShowBadge: true,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = message.data.isEmpty ? null : json.encode(message.data);

    try {
      await _notifications.show(
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      // Show notification failed
    }
  }

  /// Route the user when they tap an FCM notification (bg/terminated).
  void _handleRemoteTap(RemoteMessage message) {
    _routeFromData(message.data);
  }

  /// Route based on a notification data map (FCM data or local payload).
  ///
  /// Priority:
  ///   1. `order_id` → order details screen.
  ///   2. `url` → mapped to a known app route (e.g. `/offers` → products).
  ///   3. Type `order` → orders list.
  ///   4. Anything else → open the in-app notifications screen so the tap
  ///      always lands somewhere meaningful (broadcast/promo/general).
  void _routeFromData(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (data.isNotEmpty) {
      // 1) Order routing.
      final orderIdRaw = data['order_id'] ?? data['orderId'];
      if (orderIdRaw != null) {
        final orderId = int.tryParse(orderIdRaw.toString());
        if (orderId != null) {
          navigator.pushNamed(
            AppRoutes.orderDetails,
            arguments: {'orderId': orderId},
          );
          return;
        }
      }

      // 2) URL-based routing.
      final url = data['url']?.toString();
      final urlRoute = _routeFromUrl(url);
      if (urlRoute != null) {
        navigator.pushNamed(urlRoute);
        return;
      }

      // 3) Type-based fallback.
      final type = data['type']?.toString();
      if (type == 'order') {
        navigator.pushNamed(AppRoutes.orders);
        return;
      }
    }

    // 4) Default — open the notifications list so the user sees the new message.
    navigator.pushNamed(AppRoutes.notifications);
  }

  /// Map a notification `url` value (e.g. `/offers`) to an app route name.
  String? _routeFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final path = url.startsWith('/') ? url.substring(1) : url;
    switch (path) {
      case 'home':
        return AppRoutes.home;
      case 'products':
      case 'offers':
        return AppRoutes.products;
      case 'cart':
        return AppRoutes.cart;
      case 'wishlist':
        return AppRoutes.wishlist;
      case 'orders':
        return AppRoutes.orders;
      case 'profile':
        return AppRoutes.profile;
      case 'notifications':
        return AppRoutes.notifications;
    }
    return null;
  }

  /// Check if app was launched from a local notification (tray tap).
  Future<void> _checkInitialNotification() async {
    try {
      final details = await _notifications.getNotificationAppLaunchDetails();
      if (details != null &&
          details.didNotificationLaunchApp &&
          details.notificationResponse != null) {
        // Delay to ensure navigation is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _onNotificationTapped(details.notificationResponse!);
        });
      }
    } catch (e) {
      // Check initial notification failed
    }
  }

  /// Create Android notification channels.
  Future<void> _createNotificationChannels() async {
    const orderChannel = AndroidNotificationChannel(
      _orderChannelId,
      _orderChannelName,
      description: _orderChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const generalChannel = AndroidNotificationChannel(
      _generalChannelId,
      _generalChannelName,
      description: _generalChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(orderChannel);
      await androidPlugin?.createNotificationChannel(generalChannel);
    } catch (e) {
      // Channel creation failed
    }
  }

  /// Handle local notification tap (foreground-shown push or scheduled local).
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
      return;
    }

    // Try JSON first (FCM data map encoded by [_showRemoteAsLocal]).
    try {
      final decoded = json.decode(payload);
      if (decoded is Map<String, dynamic>) {
        _routeFromData(decoded);
        return;
      }
    } catch (_) {
      // Fall through to legacy plain-orderId payload format.
    }

    final orderId = int.tryParse(payload);
    if (orderId != null) {
      navigatorKey.currentState?.pushNamed(
        AppRoutes.orderDetails,
        arguments: {'orderId': orderId},
      );
      return;
    }

    // Unknown payload — at least land on the notifications list.
    navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
  }

  /// Request notification permissions (for iOS and Android 13+)
  Future<bool> requestPermissions() async {
    try {
      // iOS permissions
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        _permissionGranted = granted ?? false;
        return _permissionGranted;
      }

      // Android 13+ permissions
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        _permissionGranted = granted ?? true; // Default true for older Android
        return _permissionGranted;
      }

      _permissionGranted = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Show a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
      await requestPermissions();
    }

    const androidDetails = AndroidNotificationDetails(
      _orderChannelId,
      _orderChannelName,
      channelDescription: _orderChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      channelShowBadge: true,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      // Show notification failed
    }
  }

  /// Show notification from AppNotification model
  Future<void> showAppNotification(AppNotification notification) async {
    await showNotification(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.message,
      payload: notification.orderId?.toString(),
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
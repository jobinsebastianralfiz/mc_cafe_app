import 'package:flutter/foundation.dart';

import '../core/config/storage_keys.dart';
import '../core/enums/app_enums.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';

/// Notification Provider
///
/// Manages in-app notifications state and triggers local push notifications.
class NotificationProvider extends ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notificationService;
  final NotificationRepository _repository;

  NotificationProvider({
    StorageService? storage,
    NotificationService? notificationService,
    NotificationRepository? repository,
  })  : _storage = storage ?? StorageService.instance,
        _notificationService = notificationService ?? NotificationService.instance,
        _repository = repository ?? NotificationRepository();

  // ============== State ==============

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _pushEnabled = true;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;

  // ============== Getters ==============

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get pushEnabled => _pushEnabled;
  String? get error => _error;
  bool get hasMore => _currentPage < _lastPage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  // ============== Initialize ==============

  /// Initialize provider and load saved notifications
  Future<void> init() async {
    // Initialize notification service
    await _notificationService.init();

    // Request permissions
    await _notificationService.requestPermissions();

    // Load push enabled preference
    _pushEnabled = _storage.getBool(StorageKeys.pushNotificationEnabled) ?? true;

    // Load saved notifications (fast, from disk)
    await _loadNotifications();

    // Refresh from backend in the background — don't block UI on it.
    if (_storage.isLoggedIn) {
      // ignore: unawaited_futures
      loadFromApi();
    }
  }

  /// Load notifications from local storage
  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonString = _storage.getString(StorageKeys.notifications);
      if (jsonString != null && jsonString.isNotEmpty) {
        _notifications = NotificationListHelper.decode(jsonString);
        // Sort by date (newest first)
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      _notifications = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save notifications to local storage
  Future<void> _saveNotifications() async {
    try {
      final jsonString = NotificationListHelper.encode(_notifications);
      await _storage.setString(StorageKeys.notifications, jsonString);
    } catch (e) {
      // Save notifications failed
    }
  }

  // ============== API ==============

  /// Fetch notifications from the backend (page 1) and replace the list.
  ///
  /// Falls back to keeping whatever is already in [_notifications] (loaded
  /// from local storage) if the request fails — so the screen never goes
  /// blank just because the user is offline.
  Future<void> loadFromApi() async {
    if (!_storage.isLoggedIn) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final page = await _repository.getNotifications(page: 1);
      _notifications = page.items;
      _currentPage = page.currentPage;
      _lastPage = page.lastPage;
      await _saveNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load the next page and append to the list.
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || !_storage.isLoggedIn) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _repository.getNotifications(page: _currentPage + 1);
      // De-dupe by id in case the backend overlaps pages.
      final existingIds = _notifications.map((n) => n.id).toSet();
      _notifications.addAll(page.items.where((n) => !existingIds.contains(n.id)));
      _currentPage = page.currentPage;
      _lastPage = page.lastPage;
    } catch (_) {
      // Silent — pagination failures shouldn't bubble up.
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ============== Add Notifications ==============

  /// Add a new notification
  Future<void> addNotification(AppNotification notification) async {
    // Add to list
    _notifications.insert(0, notification);

    // Limit to 50 notifications
    if (_notifications.length > 50) {
      _notifications = _notifications.sublist(0, 50);
    }

    // Save to storage
    await _saveNotifications();

    // Show push notification if enabled
    if (_pushEnabled) {
      await _notificationService.showAppNotification(notification);
    }

    notifyListeners();
  }

  /// Add order status notification
  Future<void> addOrderStatusNotification({
    required int orderId,
    required String orderNumber,
    required OrderStatus status,
    String? itemsSummary,
  }) async {
    final notification = AppNotification.orderStatusNotification(
      orderId: orderId,
      orderNumber: orderNumber,
      status: status,
      itemsSummary: itemsSummary,
    );

    await addNotification(notification);
  }

  // ============== Mark as Read ==============

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    await _saveNotifications();
    notifyListeners();

    // Sync with backend (best-effort, won't block UI).
    if (_storage.isLoggedIn) {
      // ignore: unawaited_futures
      _repository.markAllAsRead();
    }
  }

  // ============== Delete Notifications ==============

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    _notifications = [];
    await _saveNotifications();
    notifyListeners();
  }

  // ============== Settings ==============

  /// Toggle push notifications
  Future<void> togglePushNotifications(bool enabled) async {
    _pushEnabled = enabled;
    await _storage.setBool(StorageKeys.pushNotificationEnabled, enabled);
    notifyListeners();
  }

  // ============== Reset ==============

  /// Reset state (for logout)
  void reset() {
    _notifications = [];
    notifyListeners();
  }
}
import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../models/notification_model.dart';

/// Notification Repository
///
/// Handles `/notifications` API calls.
///
/// Backend response shape (paginated):
/// ```
/// {
///   "data": [ { id, title, body, data:{type,url,...}, sent_at } ],
///   "current_page": 1,
///   "last_page": 3,
///   "total": 52
/// }
/// ```
class NotificationRepository {
  final ApiService _apiService;

  NotificationRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// GET /notifications — paginated, newest first.
  Future<NotificationsPage> getNotifications({int page = 1}) async {
    final response = await _apiService.get(
      ApiConfig.notifications,
      queryParams: {'page': page},
    );

    final raw = response.data;
    final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};

    // The backend returns the list on `data`; some endpoints in this app wrap
    // payloads as `{ success, data: { ... } }` — handle both.
    List<dynamic> items;
    int currentPage = page;
    int lastPage = page;
    int total = 0;

    final list = map['data'];
    if (list is List) {
      items = list;
      currentPage = (map['current_page'] as int?) ?? page;
      lastPage = (map['last_page'] as int?) ?? page;
      total = (map['total'] as int?) ?? items.length;
    } else if (list is Map<String, dynamic>) {
      // Wrapped: { success, data: { data:[...], current_page, ... } }
      final inner = list['data'];
      items = inner is List ? inner : const [];
      currentPage = (list['current_page'] as int?) ?? page;
      lastPage = (list['last_page'] as int?) ?? page;
      total = (list['total'] as int?) ?? items.length;
    } else {
      items = const [];
    }

    final notifications = items
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();

    return NotificationsPage(
      items: notifications,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  /// POST /notifications/read with `{id}` — mark a single notification as read.
  Future<void> markAsRead(String id) async {
    try {
      await _apiService.post(
        ApiConfig.markNotificationRead,
        body: {'id': id},
      );
    } catch (_) {
      // Read-state is best-effort; failures don't block UX.
    }
  }

  /// POST /notifications/read-all — mark all as read.
  Future<void> markAllAsRead() async {
    try {
      await _apiService.post(ApiConfig.markAllNotificationsRead);
    } catch (_) {
      // Best-effort.
    }
  }
}

/// One page of notifications from the backend.
class NotificationsPage {
  final List<AppNotification> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const NotificationsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}
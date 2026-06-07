import 'dart:convert';

import '../../core/enums/app_enums.dart';

/// App Notification Model
///
/// Represents an in-app notification for order updates and other events.
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final int? orderId;
  final String? orderNumber;
  final OrderStatus? orderStatus;
  final String? actionUrl;
  final Map<String, dynamic>? rawData;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.orderId,
    this.orderNumber,
    this.orderStatus,
    this.actionUrl,
    this.rawData,
  });

  /// Create notification from JSON.
  ///
  /// Accepts both the backend `/api/notifications` shape
  /// (`{ id, title, body, data: {...}, sent_at }`) and the legacy locally
  /// persisted shape (`{ id, type, message, created_at, ... }`). The backend
  /// nests routing hints (type, url, order_id) inside `data`.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final dataMap = data is Map<String, dynamic> ? data : null;

    // Title / message
    final title = json['title'] as String? ?? '';
    final message = (json['message'] ?? json['body']) as String? ?? '';

    // Type — top-level for legacy, nested in data for backend payload.
    final typeValue = (json['type'] ?? dataMap?['type']) as String? ?? 'general';

    // Created at — `created_at` legacy, `sent_at` backend.
    final createdRaw = (json['created_at'] ?? json['sent_at']) as String?;
    final createdAt = createdRaw != null
        ? DateTime.tryParse(createdRaw) ?? DateTime.now()
        : DateTime.now();

    // Order routing data may live at the top level (legacy) or under `data`.
    final orderIdRaw = json['order_id'] ?? dataMap?['order_id'];
    final orderId = orderIdRaw is int
        ? orderIdRaw
        : int.tryParse(orderIdRaw?.toString() ?? '');

    final orderNumber =
        (json['order_number'] ?? dataMap?['order_number']) as String?;

    final orderStatusValue =
        (json['order_status'] ?? dataMap?['order_status']) as String?;

    final actionUrl = (json['url'] ?? dataMap?['url']) as String?;

    return AppNotification(
      id: json['id'].toString(),
      type: NotificationType.fromValue(typeValue),
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: json['is_read'] as bool? ?? json['read_at'] != null,
      orderId: orderId,
      orderNumber: orderNumber,
      orderStatus: orderStatusValue != null
          ? OrderStatus.fromValue(orderStatusValue)
          : null,
      actionUrl: actionUrl,
      rawData: dataMap,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'order_id': orderId,
      'order_number': orderNumber,
      'order_status': orderStatus?.value,
      'url': actionUrl,
      'data': rawData,
    };
  }

  /// Create a copy with updated fields
  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    int? orderId,
    String? orderNumber,
    OrderStatus? orderStatus,
    String? actionUrl,
    Map<String, dynamic>? rawData,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      orderStatus: orderStatus ?? this.orderStatus,
      actionUrl: actionUrl ?? this.actionUrl,
      rawData: rawData ?? this.rawData,
    );
  }

  /// Get relative time string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
  }

  /// Get icon asset path based on notification type
  String get iconAsset {
    switch (type) {
      case NotificationType.order:
        if (orderStatus != null) {
          switch (orderStatus!) {
            case OrderStatus.confirmed:
              return 'assets/icons/notif_order.png';
            case OrderStatus.preparing:
              return 'assets/icons/notif_order.png';
            case OrderStatus.ready:
              return 'assets/icons/notif_order.png';
            case OrderStatus.outForDelivery:
              return 'assets/icons/notif_delivery.png';
            case OrderStatus.delivered:
            case OrderStatus.completed:
              return 'assets/icons/notif_order.png';
            case OrderStatus.cancelled:
            case OrderStatus.refunded:
              return 'assets/icons/notif_order.png';
            default:
              return 'assets/icons/notif_order.png';
          }
        }
        return 'assets/icons/notif_order.png';
      case NotificationType.promotion:
        return 'assets/icons/notif_discount.png';
      case NotificationType.general:
        return 'assets/icons/notif_new.png';
      case NotificationType.system:
        return 'assets/icons/notif_reward.png';
    }
  }

  /// Create an order status notification
  static AppNotification orderStatusNotification({
    required int orderId,
    required String orderNumber,
    required OrderStatus status,
    String? itemsSummary,
  }) {
    String title;
    String message;

    switch (status) {
      case OrderStatus.confirmed:
        title = 'Order Confirmed';
        message = itemsSummary != null
            ? 'Your $itemsSummary order has been confirmed.'
            : 'Your order #$orderNumber has been confirmed.';
        break;
      case OrderStatus.preparing:
        title = 'Order Being Prepared';
        message = 'Your order #$orderNumber is being prepared.';
        break;
      case OrderStatus.ready:
        title = 'Order Ready';
        message = 'Your order #$orderNumber is ready for pickup!';
        break;
      case OrderStatus.outForDelivery:
        title = 'Out for Delivery';
        message = 'Your order #$orderNumber is on the way!';
        break;
      case OrderStatus.delivered:
        title = 'Order Delivered';
        message = 'Your order #$orderNumber has been delivered. Enjoy!';
        break;
      case OrderStatus.completed:
        title = 'Thank You! 🎉';
        message = 'Thank you for shopping with us! Your order #$orderNumber is complete. We hope to see you again soon!';
        break;
      case OrderStatus.cancelled:
        title = 'Order Cancelled';
        message = 'Your order #$orderNumber has been cancelled.';
        break;
      case OrderStatus.refunded:
        title = 'Order Refunded';
        message = 'Your order #$orderNumber has been refunded.';
        break;
      default:
        title = 'Order Update';
        message = 'Your order #$orderNumber status: ${status.displayName}';
    }

    return AppNotification(
      id: '${orderId}_${status.value}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.order,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      orderId: orderId,
      orderNumber: orderNumber,
      orderStatus: status,
    );
  }

  @override
  String toString() => 'AppNotification(id: $id, title: $title, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Helper to encode/decode list of notifications
class NotificationListHelper {
  static String encode(List<AppNotification> notifications) {
    return jsonEncode(notifications.map((n) => n.toJson()).toList());
  }

  static List<AppNotification> decode(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
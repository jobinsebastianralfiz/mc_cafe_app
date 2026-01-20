import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/services/api_service.dart';
import '../models/order_model.dart';

/// Order Repository
///
/// Handles all order-related API calls.
class OrderRepository {
  final ApiService _apiService;

  OrderRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  // ============== Checkout ==============

  /// Place a new order (checkout)
  ///
  /// [orderType] - 'pickup' or 'delivery'
  /// [paymentMethod] - 'pay_at_counter' or 'online'
  /// [deliveryAddress] - Required for delivery orders
  /// [notes] - Optional order notes
  Future<CheckoutResult> checkout({
    required String orderType,
    required String paymentMethod,
    String? deliveryAddress,
    String? notes,
  }) async {
    debugPrint('🔵 [OrderRepository] checkout called');
    debugPrint('🔵 [OrderRepository] orderType: $orderType, paymentMethod: $paymentMethod');

    final body = <String, dynamic>{
      'order_type': orderType,
      'payment_method': paymentMethod,
    };

    if (deliveryAddress != null && deliveryAddress.isNotEmpty) {
      body['delivery_address'] = deliveryAddress;
    }

    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }

    final response = await _apiService.post(
      ApiConfig.checkout,
      body: body,
    );

    if (response['success'] != true) {
      throw ApiException(
        message: response['message'] as String? ?? 'Failed to place order',
      );
    }

    debugPrint('🟢 [OrderRepository] Order placed successfully');

    final data = response['data'] as Map<String, dynamic>;
    final order = Order.fromJson(data['order'] as Map<String, dynamic>);
    final payment = PaymentInfo.fromJson(data['payment'] as Map<String, dynamic>);

    return CheckoutResult(order: order, payment: payment);
  }

  // ============== Get Orders ==============

  /// Get user's orders list
  Future<OrdersListResult> getOrders({int page = 1}) async {
    debugPrint('🔵 [OrderRepository] getOrders called, page: $page');

    final response = await _apiService.get(
      ApiConfig.orders,
      queryParams: {'page': page},
    );

    if (response['success'] != true) {
      throw ApiException(
        message: response['message'] as String? ?? 'Failed to load orders',
      );
    }

    debugPrint('🟢 [OrderRepository] Orders loaded');

    final data = response['data'] as Map<String, dynamic>;
    final ordersJson = data['orders'] as List? ?? [];
    final orders = ordersJson
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();

    final paginationJson = data['pagination'] as Map<String, dynamic>?;
    final pagination = paginationJson != null
        ? OrderPagination.fromJson(paginationJson)
        : const OrderPagination();

    return OrdersListResult(orders: orders, pagination: pagination);
  }

  // ============== Get Order Details ==============

  /// Get single order details
  Future<Order> getOrderDetails(int orderId) async {
    debugPrint('🔵 [OrderRepository] getOrderDetails called, orderId: $orderId');

    final response = await _apiService.get(
      '${ApiConfig.orderDetails}/$orderId',
    );

    if (response['success'] != true) {
      throw ApiException(
        message: response['message'] as String? ?? 'Failed to load order details',
      );
    }

    debugPrint('🟢 [OrderRepository] Order details loaded');

    final data = response['data'] as Map<String, dynamic>;
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  // ============== Track Order ==============

  /// Track order status
  Future<OrderTrackingInfo> trackOrder(int orderId) async {
    debugPrint('🔵 [OrderRepository] trackOrder called, orderId: $orderId');

    final response = await _apiService.get(
      '${ApiConfig.orderTrack}/$orderId/track',
    );

    if (response['success'] != true) {
      throw ApiException(
        message: response['message'] as String? ?? 'Failed to track order',
      );
    }

    debugPrint('🟢 [OrderRepository] Order tracking info loaded');

    final data = response['data'] as Map<String, dynamic>;
    return OrderTrackingInfo.fromJson(data);
  }

  // ============== Cancel Order ==============

  /// Cancel an order
  Future<bool> cancelOrder(int orderId) async {
    debugPrint('🔵 [OrderRepository] cancelOrder called, orderId: $orderId');

    final response = await _apiService.post(
      '${ApiConfig.orderCancel}/$orderId/cancel',
    );

    if (response['success'] != true) {
      throw ApiException(
        message: response['message'] as String? ?? 'Failed to cancel order',
      );
    }

    debugPrint('🟢 [OrderRepository] Order cancelled');
    return true;
  }

  // ============== Reorder ==============

  /// Reorder items from a previous order
  Future<ReorderResult> reorder(int orderId) async {
    debugPrint('🔵 [OrderRepository] reorder called, orderId: $orderId');

    final response = await _apiService.post(
      '${ApiConfig.orderReorder}/$orderId/reorder',
    );

    if (response['success'] != true) {
      throw ApiException(
        message: response['message'] as String? ?? 'Failed to reorder',
      );
    }

    debugPrint('🟢 [OrderRepository] Reorder successful');

    final data = response['data'] as Map<String, dynamic>;
    return ReorderResult(
      addedItems: data['added_items'] as int? ?? 0,
      skippedItems: (data['skipped_items'] as List?)?.cast<String>() ?? [],
      message: response['message'] as String? ?? 'Items added to cart',
    );
  }

  // ============== Get Order by Token ==============

  /// Get order by token number
  Future<Order> getOrderByToken(int token, String date) async {
    debugPrint('🔵 [OrderRepository] getOrderByToken called, token: $token, date: $date');

    final response = await _apiService.get(
      ApiConfig.orderByToken,
      queryParams: {
        'token': token,
        'date': date,
      },
    );

    if (response['success'] != true) {
      throw ApiException(
        message: response['message'] as String? ?? 'Failed to find order',
      );
    }

    debugPrint('🟢 [OrderRepository] Order found by token');

    final data = response['data'] as Map<String, dynamic>;
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }
}

/// Checkout Result Model
class CheckoutResult {
  final Order order;
  final PaymentInfo payment;

  const CheckoutResult({
    required this.order,
    required this.payment,
  });
}

/// Payment Info Model
class PaymentInfo {
  final bool required;
  final String method;
  final double amount;
  final String currency;
  final String? paymentUrl;
  final String instructions;

  const PaymentInfo({
    required this.required,
    required this.method,
    required this.amount,
    required this.currency,
    this.paymentUrl,
    required this.instructions,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      required: json['required'] as bool? ?? false,
      method: json['method'] as String? ?? '',
      amount: _parseDouble(json['amount']),
      currency: json['currency'] as String? ?? 'GBP',
      paymentUrl: json['payment_url'] as String?,
      instructions: json['instructions'] as String? ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Orders List Result
class OrdersListResult {
  final List<Order> orders;
  final OrderPagination pagination;

  const OrdersListResult({
    required this.orders,
    required this.pagination,
  });
}

/// Order Pagination Model
class OrderPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const OrderPagination({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 10,
    this.total = 0,
  });

  factory OrderPagination.fromJson(Map<String, dynamic> json) {
    return OrderPagination(
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
    );
  }

  bool get hasMore => currentPage < lastPage;
}

/// Order Tracking Info Model
class OrderTrackingInfo {
  final int orderId;
  final String orderNumber;
  final String token;
  final String currentStatus;
  final String statusLabel;
  final String orderType;
  final String? estimatedTime;
  final List<TrackingStep> timeline;
  final bool isCancelled;

  const OrderTrackingInfo({
    required this.orderId,
    required this.orderNumber,
    required this.token,
    required this.currentStatus,
    required this.statusLabel,
    required this.orderType,
    this.estimatedTime,
    required this.timeline,
    required this.isCancelled,
  });

  factory OrderTrackingInfo.fromJson(Map<String, dynamic> json) {
    final timelineJson = json['timeline'] as List? ?? [];
    return OrderTrackingInfo(
      orderId: json['order_id'] as int,
      orderNumber: json['order_number'] as String? ?? '',
      token: json['token'] as String? ?? '',
      currentStatus: json['current_status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      orderType: json['order_type'] as String? ?? '',
      estimatedTime: json['estimated_time'] as String?,
      timeline: timelineJson
          .map((e) => TrackingStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCancelled: json['is_cancelled'] as bool? ?? false,
    );
  }
}

/// Tracking Step Model
class TrackingStep {
  final String label;
  final String icon;
  final bool completed;
  final bool current;

  const TrackingStep({
    required this.label,
    required this.icon,
    required this.completed,
    this.current = false,
  });

  factory TrackingStep.fromJson(Map<String, dynamic> json) {
    return TrackingStep(
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      current: json['current'] as bool? ?? false,
    );
  }
}

/// Reorder Result Model
class ReorderResult {
  final int addedItems;
  final List<String> skippedItems;
  final String message;

  const ReorderResult({
    required this.addedItems,
    required this.skippedItems,
    required this.message,
  });
}

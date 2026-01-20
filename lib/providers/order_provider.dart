import 'package:flutter/foundation.dart';

import '../core/enums/app_enums.dart';
import '../core/exceptions/api_exception.dart';
import '../data/models/order_model.dart';
import '../data/repositories/order_repository.dart';

/// Order Provider
///
/// Manages order state using ChangeNotifier for Provider.
class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository;

  OrderProvider({
    OrderRepository? repository,
  }) : _repository = repository ?? OrderRepository();

  // ============== State ==============

  List<Order> _orders = [];
  Order? _currentOrder;
  OrderTrackingInfo? _trackingInfo;
  CheckoutResult? _lastCheckoutResult;
  OrderPagination _pagination = const OrderPagination();
  LoadingStatus _status = LoadingStatus.initial;
  LoadingStatus _checkoutStatus = LoadingStatus.initial;
  LoadingStatus _detailsStatus = LoadingStatus.initial;
  LoadingStatus _trackingStatus = LoadingStatus.initial;
  String? _errorMessage;

  // ============== Getters ==============

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  OrderTrackingInfo? get trackingInfo => _trackingInfo;
  CheckoutResult? get lastCheckoutResult => _lastCheckoutResult;
  OrderPagination get pagination => _pagination;
  LoadingStatus get status => _status;
  LoadingStatus get checkoutStatus => _checkoutStatus;
  LoadingStatus get detailsStatus => _detailsStatus;
  LoadingStatus get trackingStatus => _trackingStatus;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == LoadingStatus.loading;
  bool get isCheckingOut => _checkoutStatus == LoadingStatus.loading;
  bool get hasMore => _pagination.hasMore;

  /// Get orders filtered by status
  List<Order> get upcomingOrders => _orders.where((o) => o.isActive).toList();
  List<Order> get pastOrders =>
      _orders.where((o) => o.isCompleted || o.isCancelled).toList();

  // ============== Checkout ==============

  /// Place a new order
  Future<CheckoutResult?> checkout({
    required String orderType,
    required String paymentMethod,
    String? deliveryAddress,
    String? notes,
  }) async {
    debugPrint('🔵 [OrderProvider] checkout called');
    debugPrint('🔵 [OrderProvider] orderType: $orderType, paymentMethod: $paymentMethod');

    _checkoutStatus = LoadingStatus.loading;
    _clearError();
    notifyListeners();

    try {
      final result = await _repository.checkout(
        orderType: orderType,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        notes: notes,
      );

      _lastCheckoutResult = result;
      _currentOrder = result.order;
      debugPrint('🟢 [OrderProvider] Checkout successful, orderId: ${result.order.id}');
      _checkoutStatus = LoadingStatus.success;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      debugPrint('🔴 [OrderProvider] ApiException: ${e.message}');
      _setError(e.message);
      _checkoutStatus = LoadingStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('🔴 [OrderProvider] Error: $e');
      _setError('Failed to place order');
      _checkoutStatus = LoadingStatus.error;
      notifyListeners();
      return null;
    }
  }

  // ============== Load Orders ==============

  /// Load orders list
  Future<void> loadOrders({bool refresh = false}) async {
    debugPrint('🔵 [OrderProvider] loadOrders called, refresh: $refresh');

    if (_status == LoadingStatus.loading && !refresh) return;

    if (refresh) {
      _orders = [];
      _pagination = const OrderPagination();
    }

    _status = LoadingStatus.loading;
    _clearError();
    notifyListeners();

    try {
      final result = await _repository.getOrders(
        page: refresh ? 1 : _pagination.currentPage + 1,
      );

      if (refresh) {
        _orders = result.orders;
      } else {
        _orders.addAll(result.orders);
      }
      _pagination = result.pagination;

      debugPrint('🟢 [OrderProvider] Orders loaded: ${_orders.length}');
      _status = LoadingStatus.success;
    } on ApiException catch (e) {
      debugPrint('🔴 [OrderProvider] ApiException: ${e.message}');
      _setError(e.message);
      _status = LoadingStatus.error;
    } catch (e) {
      debugPrint('🔴 [OrderProvider] Error: $e');
      _setError('Failed to load orders');
      _status = LoadingStatus.error;
    }

    notifyListeners();
  }

  /// Load more orders (pagination)
  Future<void> loadMoreOrders() async {
    if (!hasMore || _status == LoadingStatus.loading) return;
    await loadOrders();
  }

  // ============== Order Details ==============

  /// Load order details
  Future<Order?> loadOrderDetails(int orderId) async {
    debugPrint('🔵 [OrderProvider] loadOrderDetails called, orderId: $orderId');

    _detailsStatus = LoadingStatus.loading;
    _clearError();
    notifyListeners();

    try {
      _currentOrder = await _repository.getOrderDetails(orderId);
      debugPrint('🟢 [OrderProvider] Order details loaded');
      _detailsStatus = LoadingStatus.success;
      notifyListeners();
      return _currentOrder;
    } on ApiException catch (e) {
      debugPrint('🔴 [OrderProvider] ApiException: ${e.message}');
      _setError(e.message);
      _detailsStatus = LoadingStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('🔴 [OrderProvider] Error: $e');
      _setError('Failed to load order details');
      _detailsStatus = LoadingStatus.error;
      notifyListeners();
      return null;
    }
  }

  // ============== Track Order ==============

  /// Track order status
  Future<OrderTrackingInfo?> trackOrder(int orderId) async {
    debugPrint('🔵 [OrderProvider] trackOrder called, orderId: $orderId');

    _trackingStatus = LoadingStatus.loading;
    _clearError();
    notifyListeners();

    try {
      _trackingInfo = await _repository.trackOrder(orderId);
      debugPrint('🟢 [OrderProvider] Tracking info loaded');
      _trackingStatus = LoadingStatus.success;
      notifyListeners();
      return _trackingInfo;
    } on ApiException catch (e) {
      debugPrint('🔴 [OrderProvider] ApiException: ${e.message}');
      _setError(e.message);
      _trackingStatus = LoadingStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('🔴 [OrderProvider] Error: $e');
      _setError('Failed to track order');
      _trackingStatus = LoadingStatus.error;
      notifyListeners();
      return null;
    }
  }

  // ============== Cancel Order ==============

  /// Cancel an order
  Future<bool> cancelOrder(int orderId) async {
    debugPrint('🔵 [OrderProvider] cancelOrder called, orderId: $orderId');

    try {
      final success = await _repository.cancelOrder(orderId);
      if (success) {
        // Update local order state
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          // Refresh orders list to get updated status
          await loadOrders(refresh: true);
        }
        debugPrint('🟢 [OrderProvider] Order cancelled');
      }
      return success;
    } on ApiException catch (e) {
      debugPrint('🔴 [OrderProvider] ApiException: ${e.message}');
      _setError(e.message);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('🔴 [OrderProvider] Error: $e');
      _setError('Failed to cancel order');
      notifyListeners();
      return false;
    }
  }

  // ============== Reorder ==============

  /// Reorder items from a previous order
  Future<ReorderResult?> reorder(int orderId) async {
    debugPrint('🔵 [OrderProvider] reorder called, orderId: $orderId');

    try {
      final result = await _repository.reorder(orderId);
      debugPrint('🟢 [OrderProvider] Reorder successful: ${result.addedItems} items added');
      return result;
    } on ApiException catch (e) {
      debugPrint('🔴 [OrderProvider] ApiException: ${e.message}');
      _setError(e.message);
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('🔴 [OrderProvider] Error: $e');
      _setError('Failed to reorder');
      notifyListeners();
      return null;
    }
  }

  // ============== Get Order by Token ==============

  /// Get order by token number
  Future<Order?> getOrderByToken(int token, String date) async {
    debugPrint('🔵 [OrderProvider] getOrderByToken called');

    try {
      final order = await _repository.getOrderByToken(token, date);
      _currentOrder = order;
      notifyListeners();
      return order;
    } on ApiException catch (e) {
      debugPrint('🔴 [OrderProvider] ApiException: ${e.message}');
      _setError(e.message);
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('🔴 [OrderProvider] Error: $e');
      _setError('Failed to find order');
      notifyListeners();
      return null;
    }
  }

  // ============== Private Helpers ==============

  void _setError(String message) {
    _errorMessage = message;
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset state (for logout)
  void reset() {
    _orders = [];
    _currentOrder = null;
    _trackingInfo = null;
    _lastCheckoutResult = null;
    _pagination = const OrderPagination();
    _status = LoadingStatus.initial;
    _checkoutStatus = LoadingStatus.initial;
    _detailsStatus = LoadingStatus.initial;
    _trackingStatus = LoadingStatus.initial;
    _clearError();
    notifyListeners();
  }
}

/// Order Status
///
/// Represents the various states an order can be in.
enum OrderStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  preparing('preparing', 'Preparing'),
  ready('ready', 'Ready'),
  outForDelivery('out_for_delivery', 'Out for Delivery'),
  delivered('delivered', 'Delivered'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled'),
  refunded('refunded', 'Refunded');

  final String value;
  final String displayName;

  const OrderStatus(this.value, this.displayName);

  /// Get OrderStatus from API value
  static OrderStatus fromValue(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  /// Check if order is active (can be tracked)
  bool get isActive =>
      this == OrderStatus.pending ||
      this == OrderStatus.confirmed ||
      this == OrderStatus.preparing ||
      this == OrderStatus.ready ||
      this == OrderStatus.outForDelivery;

  /// Check if order is completed successfully
  bool get isCompleted =>
      this == OrderStatus.delivered || this == OrderStatus.completed;

  /// Check if order was cancelled or refunded
  bool get isCancelled =>
      this == OrderStatus.cancelled || this == OrderStatus.refunded;
}

/// Payment Method
///
/// Available payment methods for orders.
enum PaymentMethod {
  cash('cash', 'Cash on Delivery'),
  payAtCounter('pay_at_counter', 'Pay at Counter'),
  online('online', 'Online Payment'),
  card('card', 'Credit/Debit Card'),
  upi('upi', 'UPI'),
  wallet('wallet', 'Wallet'),
  netBanking('net_banking', 'Net Banking');

  final String value;
  final String displayName;

  const PaymentMethod(this.value, this.displayName);

  /// Get PaymentMethod from API value
  static PaymentMethod fromValue(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }

  /// Check if payment is online
  bool get isOnline => this == PaymentMethod.online ||
      this == PaymentMethod.card ||
      this == PaymentMethod.upi ||
      this == PaymentMethod.wallet ||
      this == PaymentMethod.netBanking;
}

/// Payment Status
///
/// Represents the payment state of an order.
enum PaymentStatus {
  pending('pending', 'Pending'),
  processing('processing', 'Processing'),
  paid('paid', 'Paid'),
  completed('completed', 'Completed'),
  failed('failed', 'Failed'),
  refunded('refunded', 'Refunded'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String displayName;

  const PaymentStatus(this.value, this.displayName);

  /// Get PaymentStatus from API value
  static PaymentStatus fromValue(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  /// Check if payment is successful
  bool get isSuccessful =>
      this == PaymentStatus.completed || this == PaymentStatus.paid;

  /// Check if payment failed or was cancelled
  bool get isFailed =>
      this == PaymentStatus.failed || this == PaymentStatus.cancelled;
}

/// Order Type
///
/// Type of order placement.
enum OrderType {
  dineIn('dine_in', 'Dine In'),
  takeaway('takeaway', 'Takeaway'),
  pickup('pickup', 'Pickup'),
  delivery('delivery', 'Delivery');

  final String value;
  final String displayName;

  const OrderType(this.value, this.displayName);

  /// Get OrderType from API value
  static OrderType fromValue(String value) {
    return OrderType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderType.pickup,
    );
  }

  /// Check if order requires delivery address
  bool get requiresAddress => this == OrderType.delivery;
}

/// Product Availability
///
/// Availability status of a product.
enum ProductAvailability {
  available('available', 'Available'),
  outOfStock('out_of_stock', 'Out of Stock'),
  comingSoon('coming_soon', 'Coming Soon'),
  discontinued('discontinued', 'Discontinued');

  final String value;
  final String displayName;

  const ProductAvailability(this.value, this.displayName);

  /// Get ProductAvailability from API value
  static ProductAvailability fromValue(String value) {
    return ProductAvailability.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProductAvailability.available,
    );
  }

  /// Check if product can be ordered
  bool get canOrder => this == ProductAvailability.available;
}

/// Address Type
///
/// Type of saved address.
enum AddressType {
  home('home', 'Home'),
  work('work', 'Work'),
  other('other', 'Other');

  final String value;
  final String displayName;

  const AddressType(this.value, this.displayName);

  /// Get AddressType from API value
  static AddressType fromValue(String value) {
    return AddressType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AddressType.other,
    );
  }
}

/// Notification Type
///
/// Types of notifications in the app.
enum NotificationType {
  order('order', 'Order Update'),
  promotion('promotion', 'Promotion'),
  general('general', 'General'),
  system('system', 'System');

  final String value;
  final String displayName;

  const NotificationType(this.value, this.displayName);

  /// Get NotificationType from API value
  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.general,
    );
  }
}

/// Auth Status
///
/// Authentication state of the user.
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  pendingVerification,
}

/// Loading Status
///
/// Generic loading state for async operations.
enum LoadingStatus {
  initial,
  loading,
  success,
  error,
}

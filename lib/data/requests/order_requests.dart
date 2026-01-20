import '../../core/enums/app_enums.dart';

/// Checkout Request
///
/// Request body for creating an order.
class CheckoutRequest {
  final OrderType orderType;
  final PaymentMethod paymentMethod;
  final int? addressId;
  final String? tableNumber;
  final String? specialInstructions;
  final String? couponCode;
  final DateTime? scheduledAt;

  const CheckoutRequest({
    required this.orderType,
    required this.paymentMethod,
    this.addressId,
    this.tableNumber,
    this.specialInstructions,
    this.couponCode,
    this.scheduledAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_type': orderType.value,
      'payment_method': paymentMethod.value,
      if (addressId != null) 'address_id': addressId,
      if (tableNumber != null && tableNumber!.isNotEmpty)
        'table_number': tableNumber,
      if (specialInstructions != null && specialInstructions!.isNotEmpty)
        'special_instructions': specialInstructions,
      if (couponCode != null && couponCode!.isNotEmpty)
        'coupon_code': couponCode,
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
    };
  }

  /// Validate request before sending
  bool get isValid {
    // Delivery orders require address
    if (orderType == OrderType.delivery && addressId == null) {
      return false;
    }
    // Dine-in might require table number (depending on business rules)
    return true;
  }
}

/// Cancel Order Request
///
/// Request body for cancelling an order.
class CancelOrderRequest {
  final int orderId;
  final String? reason;

  const CancelOrderRequest({
    required this.orderId,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
    };
  }
}

/// Reorder Request
///
/// Request body for reordering a previous order.
class ReorderRequest {
  final int orderId;

  const ReorderRequest({
    required this.orderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
    };
  }
}

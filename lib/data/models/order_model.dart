import '../../core/enums/app_enums.dart';
import 'address_model.dart';

/// Order Model
///
/// Represents an order from the API.
class Order {
  final int id;
  final String orderNumber;
  final int? dailyToken;
  final String? formattedToken;
  final String? tokenDate;
  final int userId;
  final OrderStatus status;
  final OrderType orderType;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final List<OrderItem> items;
  final int itemsCount;
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double tax;
  final double total;
  final String? couponCode;
  final double? couponDiscount;
  final String? deliveryAddressText;
  final Address? deliveryAddress;
  final String? tableNumber;
  final String? specialInstructions;
  final DateTime? scheduledAt;
  final DateTime? preparedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.orderNumber,
    this.dailyToken,
    this.formattedToken,
    this.tokenDate,
    required this.userId,
    required this.status,
    required this.orderType,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    this.itemsCount = 0,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.deliveryCharge = 0.0,
    this.tax = 0.0,
    required this.total,
    this.couponCode,
    this.couponDiscount,
    this.deliveryAddressText,
    this.deliveryAddress,
    this.tableNumber,
    this.specialInstructions,
    this.scheduledAt,
    this.preparedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create Order from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] ?? json['order_items'] ?? [];
    return Order(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String? ?? json['id'].toString(),
      dailyToken: json['daily_token'] as int?,
      formattedToken: json['formatted_token'] as String?,
      tokenDate: json['token_date'] as String?,
      userId: json['user_id'] as int? ?? 0,
      status: OrderStatus.fromValue(
          json['status'] as String? ?? 'pending'),
      orderType: OrderType.fromValue(
          json['order_type'] as String? ?? 'pickup'),
      paymentMethod: PaymentMethod.fromValue(
          json['payment_method'] as String? ?? 'cash'),
      paymentStatus: PaymentStatus.fromValue(
          json['payment_status'] as String? ?? 'pending'),
      items: (itemsList as List)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemsCount: json['items_count'] as int? ?? 0,
      subtotal: _parseDouble(json['subtotal'] ?? json['sub_total']),
      discount: _parseDouble(json['discount']),
      deliveryCharge: _parseDouble(json['delivery_charge'] ?? json['delivery_fee']),
      tax: _parseDouble(json['tax'] ?? json['tax_amount']),
      total: _parseDouble(json['total'] ?? json['grand_total']),
      couponCode: json['coupon_code'] as String?,
      couponDiscount: json['coupon_discount'] != null
          ? _parseDouble(json['coupon_discount'])
          : null,
      deliveryAddressText: json['delivery_address'] is String
          ? json['delivery_address'] as String
          : null,
      deliveryAddress: json['delivery_address'] != null &&
              json['delivery_address'] is Map
          ? Address.fromJson(json['delivery_address'] as Map<String, dynamic>)
          : (json['address'] != null && json['address'] is Map
              ? Address.fromJson(json['address'] as Map<String, dynamic>)
              : null),
      tableNumber: json['table_number'] as String?,
      specialInstructions: json['special_instructions'] as String? ??
          json['notes'] as String?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      preparedAt: json['prepared_at'] != null
          ? DateTime.tryParse(json['prepared_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert Order to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'daily_token': dailyToken,
      'formatted_token': formattedToken,
      'token_date': tokenDate,
      'user_id': userId,
      'status': status.value,
      'order_type': orderType.value,
      'payment_method': paymentMethod.value,
      'payment_status': paymentStatus.value,
      'items': items.map((e) => e.toJson()).toList(),
      'items_count': itemsCount,
      'subtotal': subtotal,
      'discount': discount,
      'delivery_charge': deliveryCharge,
      'tax': tax,
      'total': total,
      'coupon_code': couponCode,
      'coupon_discount': couponDiscount,
      'delivery_address': deliveryAddressText ?? deliveryAddress?.toJson(),
      'table_number': tableNumber,
      'special_instructions': specialInstructions,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'prepared_at': preparedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get actual item count
  int get actualItemCount =>
      itemsCount > 0 ? itemsCount : items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if order is active
  bool get isActive => status.isActive;

  /// Check if order is completed
  bool get isCompleted => status.isCompleted;

  /// Check if order is cancelled
  bool get isCancelled => status.isCancelled;

  /// Check if order can be cancelled
  bool get canBeCancelled =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  /// Check if order can be reordered
  bool get canBeReordered => isCompleted || isCancelled;

  /// Check if payment is completed
  bool get isPaid => paymentStatus.isSuccessful;

  /// Get total items count
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Parse double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  String toString() =>
      'Order(id: $id, orderNumber: $orderNumber, status: ${status.displayName})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Order Item Model
///
/// Represents an individual item in an order.
class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final int? variantId;
  final String? variantName;
  final List<OrderItemAddon>? addons;
  final String? specialInstructions;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.variantId,
    this.variantName,
    this.addons,
    this.specialInstructions,
  });

  /// Create OrderItem from JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Handle customizations field that contains addons and variant
    final customizations = json['customizations'] as Map<String, dynamic>?;
    List<OrderItemAddon>? addons;
    int? variantId;
    String? variantName;
    String? specialInstructions;

    if (customizations != null) {
      // Parse addons from customizations
      final addonsData = customizations['addons'] as List?;
      if (addonsData != null && addonsData.isNotEmpty) {
        addons = addonsData
            .map((e) => OrderItemAddon.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Parse variant from customizations
      final variantData = customizations['variant'] as Map<String, dynamic>?;
      if (variantData != null) {
        variantId = variantData['id'] as int?;
        variantName = variantData['name'] as String?;
      }

      specialInstructions = customizations['special_instructions'] as String?;
    }

    // Fallback to direct fields if customizations not present
    if (addons == null && json['addons'] != null) {
      addons = (json['addons'] as List)
          .map((e) => OrderItemAddon.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    variantId ??= json['variant_id'] as int?;
    variantName ??= json['variant_name'] as String?;
    specialInstructions ??= json['special_instructions'] as String?;

    return OrderItem(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String? ??
          (json['product'] is Map ? json['product']['name'] as String? : null) ??
          '',
      productImage: json['product_image'] as String? ??
          (json['product'] is Map ? json['product']['image'] as String? : null),
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: Order._parseDouble(json['unit_price'] ?? json['price']),
      totalPrice: Order._parseDouble(json['total_price'] ?? json['subtotal'] ?? json['total']),
      variantId: variantId,
      variantName: variantName,
      addons: addons,
      specialInstructions: specialInstructions,
    );
  }

  /// Convert OrderItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'variant_id': variantId,
      'variant_name': variantName,
      'addons': addons?.map((e) => e.toJson()).toList(),
      'special_instructions': specialInstructions,
    };
  }

  /// Check if item has addons
  bool get hasAddons => addons != null && addons!.isNotEmpty;

  @override
  String toString() =>
      'OrderItem(productName: $productName, quantity: $quantity)';
}

/// Order Item Addon Model
///
/// Represents an addon in an order item.
class OrderItemAddon {
  final int id;
  final String name;
  final double price;
  final int quantity;

  const OrderItemAddon({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  factory OrderItemAddon.fromJson(Map<String, dynamic> json) {
    return OrderItemAddon(
      id: json['id'] as int? ?? json['addon_id'] as int? ?? 0,
      name: json['name'] as String? ?? json['addon_name'] as String? ?? '',
      price: Order._parseDouble(json['price']),
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  @override
  String toString() => 'OrderItemAddon(name: $name, price: $price)';
}

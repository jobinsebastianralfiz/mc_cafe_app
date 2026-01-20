import 'product_model.dart';

/// Cart Model
///
/// Represents the user's shopping cart from the API.
/// API Response structure:
/// {
///   "id": 1,
///   "store_id": null,
///   "items": [...],
///   "items_count": 4,
///   "coupon_code": null,
///   "notes": null,
///   "summary": { "subtotal", "tax_rate", "tax", "discount", "grand_total" },
///   "currency": { "symbol": "£", "code": "GBP" }
/// }
class Cart {
  final int id;
  final int? storeId;
  final List<CartItem> items;
  final int itemsCount;
  final String? couponCode;
  final String? notes;
  final CartSummary summary;
  final CartCurrency currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Cart({
    required this.id,
    this.storeId,
    required this.items,
    this.itemsCount = 0,
    this.couponCode,
    this.notes,
    required this.summary,
    required this.currency,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Cart from JSON
  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] ?? json['cart_items'] ?? [];

    // Parse summary
    CartSummary summary;
    if (json['summary'] != null && json['summary'] is Map) {
      summary = CartSummary.fromJson(json['summary'] as Map<String, dynamic>);
    } else {
      // Fallback for flat structure
      summary = CartSummary(
        subtotal: _parseDouble(json['subtotal'] ?? json['sub_total']),
        taxRate: _parseDouble(json['tax_rate']),
        tax: _parseDouble(json['tax'] ?? json['tax_amount']),
        discount: _parseDouble(json['discount']),
        grandTotal: _parseDouble(json['total'] ?? json['grand_total']),
      );
    }

    // Parse currency
    CartCurrency currency;
    if (json['currency'] != null && json['currency'] is Map) {
      currency = CartCurrency.fromJson(json['currency'] as Map<String, dynamic>);
    } else {
      currency = const CartCurrency(symbol: '£', code: 'GBP');
    }

    return Cart(
      id: json['id'] as int? ?? 0,
      storeId: json['store_id'] as int?,
      items: (itemsList as List)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemsCount: json['items_count'] as int? ?? 0,
      couponCode: json['coupon_code'] as String?,
      notes: json['notes'] as String?,
      summary: summary,
      currency: currency,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Create empty cart
  factory Cart.empty() {
    return const Cart(
      id: 0,
      items: [],
      itemsCount: 0,
      summary: CartSummary(
        subtotal: 0,
        taxRate: 0,
        tax: 0,
        discount: 0,
        grandTotal: 0,
      ),
      currency: CartCurrency(symbol: '£', code: 'GBP'),
    );
  }

  /// Convert Cart to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'items': items.map((e) => e.toJson()).toList(),
      'items_count': itemsCount,
      'coupon_code': couponCode,
      'notes': notes,
      'summary': summary.toJson(),
      'currency': currency.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Cart copyWith({
    int? id,
    int? storeId,
    List<CartItem>? items,
    int? itemsCount,
    String? couponCode,
    String? notes,
    CartSummary? summary,
    CartCurrency? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      items: items ?? this.items,
      itemsCount: itemsCount ?? this.itemsCount,
      couponCode: couponCode ?? this.couponCode,
      notes: notes ?? this.notes,
      summary: summary ?? this.summary,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart is not empty
  bool get isNotEmpty => items.isNotEmpty;

  /// Get total number of items in cart (sum of quantities)
  int get itemCount => itemsCount > 0 ? itemsCount : items.fold(0, (sum, item) => sum + item.quantity);

  /// Get number of unique products
  int get uniqueItemCount => items.length;

  /// Get subtotal
  double get subtotal => summary.subtotal;

  /// Get total (grand total)
  double get total => summary.grandTotal;

  /// Get tax amount
  double get tax => summary.tax;

  /// Get discount amount
  double get discount => summary.discount;

  /// Check if coupon is applied
  bool get hasCoupon => couponCode != null && couponCode!.isNotEmpty;

  /// Calculate total savings
  double get totalSavings => discount;

  /// Parse double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  String toString() => 'Cart(id: $id, items: ${items.length}, total: ${summary.grandTotal})';
}

/// Cart Summary Model
class CartSummary {
  final double subtotal;
  final double taxRate;
  final double tax;
  final double discount;
  final double grandTotal;

  const CartSummary({
    required this.subtotal,
    required this.taxRate,
    required this.tax,
    required this.discount,
    required this.grandTotal,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      subtotal: Cart._parseDouble(json['subtotal']),
      taxRate: Cart._parseDouble(json['tax_rate']),
      tax: Cart._parseDouble(json['tax']),
      discount: Cart._parseDouble(json['discount']),
      grandTotal: Cart._parseDouble(json['grand_total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax': tax,
      'discount': discount,
      'grand_total': grandTotal,
    };
  }
}

/// Cart Currency Model
class CartCurrency {
  final String symbol;
  final String code;

  const CartCurrency({
    required this.symbol,
    required this.code,
  });

  factory CartCurrency.fromJson(Map<String, dynamic> json) {
    return CartCurrency(
      symbol: json['symbol'] as String? ?? '£',
      code: json['code'] as String? ?? 'GBP',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'code': code,
    };
  }
}

/// Cart Item Model
///
/// Represents an individual item in the cart.
/// API Response structure:
/// {
///   "id": 1,
///   "product_id": 1,
///   "product_name": "Bacon Burger",
///   "product_image": "...",
///   "variant_id": 1,
///   "variant_name": "Small",
///   "unit_price": 15,
///   "quantity": 4,
///   "addons": [...],
///   "addons_total": 7.78,
///   "item_total": 91.12,
///   "special_instructions": "Extra crispy please"
/// }
class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int? variantId;
  final String? variantName;
  final double unitPrice;
  final int quantity;
  final List<CartItemAddon>? addons;
  final double addonsTotal;
  final double itemTotal;
  final String? specialInstructions;
  final Product? product;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    this.variantId,
    this.variantName,
    required this.unitPrice,
    required this.quantity,
    this.addons,
    this.addonsTotal = 0,
    required this.itemTotal,
    this.specialInstructions,
    this.product,
    this.createdAt,
    this.updatedAt,
  });

  /// Create CartItem from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String? ??
          (json['product'] is Map ? json['product']['name'] as String? : null) ??
          '',
      productImage: json['product_image'] as String? ??
          (json['product'] is Map ? json['product']['image'] as String? : null),
      variantId: json['variant_id'] as int?,
      variantName: json['variant_name'] as String?,
      unitPrice: Cart._parseDouble(json['unit_price'] ?? json['price']),
      quantity: json['quantity'] as int? ?? 1,
      addons: json['addons'] != null && (json['addons'] as List).isNotEmpty
          ? (json['addons'] as List)
              .map((e) => CartItemAddon.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      addonsTotal: Cart._parseDouble(json['addons_total']),
      itemTotal: Cart._parseDouble(json['item_total'] ?? json['total_price'] ?? json['total']),
      specialInstructions: json['special_instructions'] as String?,
      product: json['product'] is Map
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert CartItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'variant_id': variantId,
      'variant_name': variantName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'addons': addons?.map((e) => e.toJson()).toList(),
      'addons_total': addonsTotal,
      'item_total': itemTotal,
      'special_instructions': specialInstructions,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  CartItem copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productImage,
    int? variantId,
    String? variantName,
    double? unitPrice,
    int? quantity,
    List<CartItemAddon>? addons,
    double? addonsTotal,
    double? itemTotal,
    String? specialInstructions,
    Product? product,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      addons: addons ?? this.addons,
      addonsTotal: addonsTotal ?? this.addonsTotal,
      itemTotal: itemTotal ?? this.itemTotal,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      product: product ?? this.product,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if item has variant
  bool get hasVariant => variantId != null;

  /// Check if item has addons
  bool get hasAddons => addons != null && addons!.isNotEmpty;

  /// Get total price (same as itemTotal)
  double get totalPrice => itemTotal;

  @override
  String toString() =>
      'CartItem(id: $id, productName: $productName, quantity: $quantity, total: $itemTotal)';
}

/// Cart Item Addon Model
///
/// Represents an addon selected for a cart item.
class CartItemAddon {
  final int id;
  final String name;
  final double price;
  final int quantity;

  const CartItemAddon({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  factory CartItemAddon.fromJson(Map<String, dynamic> json) {
    return CartItemAddon(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: Cart._parseDouble(json['price']),
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
  String toString() => 'CartItemAddon(name: $name, price: $price)';
}

import 'product_model.dart';

/// Wishlist Model
///
/// Represents a user's wishlist containing favorite products.
class Wishlist {
  final int id;
  final int userId;
  final List<WishlistItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Wishlist({
    required this.id,
    required this.userId,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Wishlist from JSON
  factory Wishlist.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] ?? json['wishlist_items'] ?? json['products'] ?? [];
    return Wishlist(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      items: (itemsList as List)
          .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Create Wishlist from list of items
  factory Wishlist.fromItems(List<dynamic> items) {
    return Wishlist(
      id: 0,
      userId: 0,
      items: items
          .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Create empty wishlist
  factory Wishlist.empty() {
    return const Wishlist(
      id: 0,
      userId: 0,
      items: [],
    );
  }

  /// Convert Wishlist to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated items
  Wishlist copyWith({
    int? id,
    int? userId,
    List<WishlistItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wishlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if wishlist is empty
  bool get isEmpty => items.isEmpty;

  /// Check if wishlist is not empty
  bool get isNotEmpty => items.isNotEmpty;

  /// Get total item count
  int get itemCount => items.length;

  /// Check if a product is in wishlist
  bool containsProduct(int productId) {
    return items.any((item) => item.productId == productId);
  }

  /// Get product IDs in wishlist
  List<int> get productIds => items.map((item) => item.productId).toList();

  @override
  String toString() => 'Wishlist(id: $id, items: ${items.length})';
}

/// Wishlist Item Model
///
/// Represents an individual item in the wishlist.
class WishlistItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final double price;
  final double? discountPrice;
  final Product? product;
  final DateTime? addedAt;

  const WishlistItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    this.discountPrice,
    this.product,
    this.addedAt,
  });

  /// Create WishlistItem from JSON
  /// Handles multiple API response formats:
  /// 1. Item with nested product: {id: 6, added_at: ..., product: {id: 1, name: ...}}
  /// 2. Product directly: {id: 1, name: ..., pivot: {id: 6, ...}}
  /// 3. Item with product_id: {id: 6, product_id: 1, product_name: ...}
  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    // Format 1: Item with nested product object (API actual format)
    // {id: 6, added_at: ..., product: {id: 1, name: "Bacon Burger", ...}}
    if (json.containsKey('product') && json['product'] is Map) {
      final productJson = json['product'] as Map<String, dynamic>;
      final product = Product.fromJson(productJson);

      return WishlistItem(
        id: json['id'] as int,
        productId: product.id,
        productName: product.name,
        productImage: productJson['image'] as String?,
        price: product.priceAsDouble,
        discountPrice: product.comparePriceAsDouble,
        product: product,
        addedAt: json['added_at'] != null
            ? DateTime.tryParse(json['added_at'] as String)
            : (json['created_at'] != null
                ? DateTime.tryParse(json['created_at'] as String)
                : null),
      );
    }

    // Format 2: Product directly with pivot (Laravel relationship format)
    // {id: 1, name: "Bacon Burger", ..., pivot: {id: 6, created_at: ...}}
    final isProductDirectly = json.containsKey('name') && !json.containsKey('product_id');
    if (isProductDirectly) {
      return WishlistItem(
        id: json['pivot']?['id'] as int? ?? json['id'] as int,
        productId: json['id'] as int,
        productName: json['name'] as String? ?? '',
        productImage: json['image'] as String?,
        price: _parseDouble(json['price'] ?? json['min_price']),
        discountPrice: json['discount_price'] != null
            ? _parseDouble(json['discount_price'])
            : null,
        product: Product.fromJson(json),
        addedAt: json['pivot']?['created_at'] != null
            ? DateTime.tryParse(json['pivot']['created_at'] as String)
            : (json['created_at'] != null
                ? DateTime.tryParse(json['created_at'] as String)
                : null),
      );
    }

    // Format 3: Item with product_id field
    // {id: 6, product_id: 1, product_name: "Bacon Burger", ...}
    return WishlistItem(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String? ?? '',
      productImage: json['product_image'] as String?,
      price: _parseDouble(json['price']),
      discountPrice: json['discount_price'] != null
          ? _parseDouble(json['discount_price'])
          : null,
      product: null,
      addedAt: json['added_at'] != null
          ? DateTime.tryParse(json['added_at'] as String)
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null),
    );
  }

  /// Convert WishlistItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'price': price,
      'discount_price': discountPrice,
      'added_at': addedAt?.toIso8601String(),
    };
  }

  /// Get effective price (discount price if available)
  double get effectivePrice => discountPrice ?? price;

  /// Check if product has discount
  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  /// Parse double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  String toString() => 'WishlistItem(id: $id, productName: $productName)';
}

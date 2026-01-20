import 'category_model.dart';

/// Product Model
///
/// Represents a product from the API with variants and addons.
/// Based on actual API response structure.
class Product {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? image;
  final List<String>? gallery;
  final bool isFeatured;
  final bool hasVariants;
  final Category? category;
  final int? categoryId;
  final Map<String, dynamic>? customizationOptions;

  // Price fields - when no variants
  final String? price;
  final String? comparePrice;
  final int? stockQuantity;
  final String? sku;

  // Price fields - when has variants
  final String? minPrice;
  final String? maxPrice;
  final String? priceRange;

  // Related data
  final List<ProductVariant> variants;
  final List<AddonGroup>? addonGroups;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    this.gallery,
    this.isFeatured = false,
    this.hasVariants = false,
    this.category,
    this.categoryId,
    this.customizationOptions,
    this.price,
    this.comparePrice,
    this.stockQuantity,
    this.sku,
    this.minPrice,
    this.maxPrice,
    this.priceRange,
    this.variants = const [],
    this.addonGroups,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      gallery: json['gallery'] != null
          ? (json['gallery'] as List).cast<String>()
          : null,
      isFeatured: json['is_featured'] as bool? ?? false,
      hasVariants: json['has_variants'] as bool? ?? false,
      category: json['category'] != null && json['category'] is Map
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      categoryId: json['category_id'] as int?,
      customizationOptions: json['customization_options'] as Map<String, dynamic>?,
      price: json['price']?.toString(),
      comparePrice: json['compare_price']?.toString(),
      stockQuantity: json['stock_quantity'] as int?,
      sku: json['sku'] as String?,
      minPrice: json['min_price']?.toString(),
      maxPrice: json['max_price']?.toString(),
      priceRange: json['price_range'] as String?,
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      addonGroups: json['addon_groups'] != null
          ? (json['addon_groups'] as List)
              .map((e) => AddonGroup.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image': image,
      'gallery': gallery,
      'is_featured': isFeatured,
      'has_variants': hasVariants,
      'category': category?.toJson(),
      'category_id': categoryId,
      'customization_options': customizationOptions,
      'price': price,
      'compare_price': comparePrice,
      'stock_quantity': stockQuantity,
      'sku': sku,
      'min_price': minPrice,
      'max_price': maxPrice,
      'price_range': priceRange,
      'variants': variants.map((e) => e.toJson()).toList(),
      'addon_groups': addonGroups?.map((e) => e.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get price as double
  double get priceAsDouble {
    if (price != null) return double.tryParse(price!) ?? 0.0;
    if (minPrice != null) return double.tryParse(minPrice!) ?? 0.0;
    return 0.0;
  }

  /// Get compare price as double (original higher price for strikethrough)
  double? get comparePriceAsDouble {
    if (comparePrice == null) return null;
    return double.tryParse(comparePrice!);
  }

  /// Check if product has discount (compare_price is the OLD higher price)
  bool get hasDiscount {
    if (comparePrice == null || price == null) return false;
    final current = double.tryParse(price!) ?? 0;
    final original = double.tryParse(comparePrice!) ?? 0;
    return original > current;
  }

  /// Get discount percentage
  int get discountPercent {
    if (!hasDiscount) return 0;
    final current = double.tryParse(price!) ?? 0;
    final original = double.tryParse(comparePrice!) ?? 0;
    if (original == 0) return 0;
    return ((original - current) / original * 100).round();
  }

  /// Get display price string
  String get displayPrice {
    if (hasVariants && priceRange != null) {
      return priceRange!;
    }
    return price ?? '0.00';
  }

  /// Check if product has addons
  bool get hasAddons => addonGroups != null && addonGroups!.isNotEmpty;

  /// Check if product is in stock
  bool get isInStock {
    if (hasVariants) {
      return variants.any((v) => (v.stockQuantity ?? 0) > 0);
    }
    return (stockQuantity ?? 0) > 0;
  }

  /// Get category name
  String? get categoryName => category?.name;

  /// Get short description (first 50 chars or first line)
  String? get shortDescription {
    if (description == null || description!.isEmpty) return null;
    final firstLine = description!.split('\n').first;
    if (firstLine.length <= 50) return firstLine;
    return '${firstLine.substring(0, 47)}...';
  }

  @override
  String toString() => 'Product(id: $id, name: $name, price: $price)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Product Variant Model
///
/// Represents a variant of a product (e.g., Small, Medium, Large).
/// Based on actual API response structure.
class ProductVariant {
  final int id;
  final String name;
  final String? sku;
  final String price;
  final String? comparePrice;
  final int? stockQuantity;

  const ProductVariant({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    this.comparePrice,
    this.stockQuantity,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      price: json['price']?.toString() ?? '0.00',
      comparePrice: json['compare_price']?.toString(),
      stockQuantity: json['stock_quantity'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'compare_price': comparePrice,
      'stock_quantity': stockQuantity,
    };
  }

  /// Get price as double
  double get priceAsDouble => double.tryParse(price) ?? 0.0;

  /// Check if variant has discount
  bool get hasDiscount {
    if (comparePrice == null) return false;
    final current = double.tryParse(price) ?? 0;
    final original = double.tryParse(comparePrice!) ?? 0;
    return original > current;
  }

  /// Check if variant is in stock
  bool get isInStock => (stockQuantity ?? 0) > 0;

  @override
  String toString() => 'ProductVariant(id: $id, name: $name, price: $price)';
}

/// Addon Group Model
///
/// Represents a group of addons (e.g., "Extra Toppings").
/// Based on actual API response structure.
class AddonGroup {
  final int id;
  final String name;
  final String? description;
  final String selectionType; // 'single' or 'multiple'
  final bool isRequired;
  final int minSelections;
  final int? maxSelections;
  final List<Addon> addons;

  const AddonGroup({
    required this.id,
    required this.name,
    this.description,
    this.selectionType = 'multiple',
    this.isRequired = false,
    this.minSelections = 0,
    this.maxSelections,
    required this.addons,
  });

  factory AddonGroup.fromJson(Map<String, dynamic> json) {
    return AddonGroup(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      selectionType: json['selection_type'] as String? ?? 'multiple',
      isRequired: json['is_required'] as bool? ?? false,
      minSelections: json['min_selections'] as int? ?? 0,
      maxSelections: json['max_selections'] as int?,
      addons: json['addons'] != null
          ? (json['addons'] as List)
              .map((e) => Addon.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'selection_type': selectionType,
      'is_required': isRequired,
      'min_selections': minSelections,
      'max_selections': maxSelections,
      'addons': addons.map((e) => e.toJson()).toList(),
    };
  }

  /// Check if multiple selection is allowed
  bool get allowsMultiple => selectionType == 'multiple';

  /// Check if single selection only
  bool get isSingleSelect => selectionType == 'single';

  @override
  String toString() => 'AddonGroup(id: $id, name: $name, addons: ${addons.length})';
}

/// Addon Model
///
/// Represents an individual addon item.
/// Based on actual API response structure.
class Addon {
  final int id;
  final String name;
  final String price;

  const Addon({
    required this.id,
    required this.name,
    required this.price,
  });

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      price: json['price']?.toString() ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }

  /// Get price as double
  double get priceAsDouble => double.tryParse(price) ?? 0.0;

  @override
  String toString() => 'Addon(id: $id, name: $name, price: $price)';
}

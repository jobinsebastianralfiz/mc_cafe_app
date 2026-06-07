import '../../core/utils/json_parsers.dart';

/// Category Model
///
/// Represents a product category from the API.
/// Based on actual API response structure.
class Category {
  final int id;
  final String name;
  final String type;
  final String slug;
  final String? image;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    this.type = 'cafe',
    required this.slug,
    this.image,
    this.sortOrder = 0,
  });

  /// Create Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: parseInt(json['id']),
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'cafe',
      slug: json['slug'] as String? ?? '',
      image: json['image'] as String?,
      sortOrder: parseInt(json['sort_order']),
    );
  }

  /// Convert Category to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'slug': slug,
      'image': image,
      'sort_order': sortOrder,
    };
  }

  /// Create a copy with updated fields
  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? slug,
    String? image,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      slug: slug ?? this.slug,
      image: image ?? this.image,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Check if this is a cafe category
  bool get isCafe => type == 'cafe';

  /// Check if this is a restaurant category
  bool get isRestaurant => type == 'restaurant';

  @override
  String toString() => 'Category(id: $id, name: $name, slug: $slug)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

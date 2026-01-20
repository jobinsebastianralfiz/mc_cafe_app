/// Category Model
///
/// Represents a product category from the API.
/// Based on actual API response structure.
class Category {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.sortOrder = 0,
  });

  /// Create Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      image: json['image'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Convert Category to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image': image,
      'sort_order': sortOrder,
    };
  }

  /// Create a copy with updated fields
  Category copyWith({
    int? id,
    String? name,
    String? slug,
    String? image,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      image: image ?? this.image,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, slug: $slug)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

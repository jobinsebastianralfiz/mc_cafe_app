/// User Model
///
/// Represents the authenticated user data from the API.
/// Based on actual API response structure.
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? address;
  final int loyaltyPoints;
  final String? loyaltyTier;
  final String? avatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'customer',
    this.address,
    this.loyaltyPoints = 0,
    this.loyaltyTier,
    this.avatar,
    this.createdAt,
    this.updatedAt,
  });

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'customer',
      address: json['address'] as String?,
      loyaltyPoints: json['loyalty_points'] as int? ?? 0,
      loyaltyTier: json['loyalty_tier'] as String?,
      avatar: json['avatar'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'address': address,
      'loyalty_points': loyaltyPoints,
      'loyalty_tier': loyaltyTier,
      'avatar': avatar,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? address,
    int? loyaltyPoints,
    String? loyaltyTier,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      address: address ?? this.address,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      loyaltyTier: loyaltyTier ?? this.loyaltyTier,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get user initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Get display name (first name only)
  String get firstName {
    final parts = name.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : name;
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is customer
  bool get isCustomer => role == 'customer';

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

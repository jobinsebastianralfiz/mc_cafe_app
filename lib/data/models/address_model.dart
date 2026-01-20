import '../../core/enums/app_enums.dart';

/// Address Model
///
/// Represents a user's saved address.
class Address {
  final int id;
  final int userId;
  final AddressType type;
  final String? label;
  final String addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String city;
  final String state;
  final String postalCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? contactName;
  final String? contactPhone;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Address({
    required this.id,
    required this.userId,
    this.type = AddressType.other,
    this.label,
    required this.addressLine1,
    this.addressLine2,
    this.landmark,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
    this.contactName,
    this.contactPhone,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Address from JSON
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      type: AddressType.fromValue(json['type'] as String? ?? 'other'),
      label: json['label'] as String?,
      addressLine1: json['address_line_1'] as String? ??
          json['address'] as String? ??
          json['street'] as String? ??
          '',
      addressLine2: json['address_line_2'] as String?,
      landmark: json['landmark'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postal_code'] as String? ??
          json['pincode'] as String? ??
          json['zip_code'] as String? ??
          '',
      country: json['country'] as String?,
      latitude: json['latitude'] != null
          ? _parseDouble(json['latitude'])
          : null,
      longitude: json['longitude'] != null
          ? _parseDouble(json['longitude'])
          : null,
      contactName: json['contact_name'] as String? ?? json['name'] as String?,
      contactPhone: json['contact_phone'] as String? ?? json['phone'] as String?,
      isDefault: json['is_default'] as bool? ?? json['default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert Address to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'label': label,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'landmark': landmark,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'is_default': isDefault,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Address copyWith({
    int? id,
    int? userId,
    AddressType? type,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? landmark,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? contactName,
    String? contactPhone,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      label: label ?? this.label,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name for the address
  String get displayName => label ?? type.displayName;

  /// Get formatted full address
  String get fullAddress {
    final parts = <String>[
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
      if (landmark != null && landmark!.isNotEmpty) landmark!,
      '$city, $state $postalCode',
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.join(', ');
  }

  /// Get short address (first line + city)
  String get shortAddress => '$addressLine1, $city';

  /// Check if address has coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Parse double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  String toString() => 'Address(id: $id, type: ${type.displayName}, city: $city)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

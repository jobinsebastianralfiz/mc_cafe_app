import '../../core/enums/app_enums.dart';

/// Add Address Request
///
/// Request body for adding a new address.
class AddAddressRequest {
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

  const AddAddressRequest({
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
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      if (label != null && label!.isNotEmpty) 'label': label,
      'address_line_1': addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty)
        'address_line_2': addressLine2,
      if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      if (country != null && country!.isNotEmpty) 'country': country,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (contactName != null && contactName!.isNotEmpty)
        'contact_name': contactName,
      if (contactPhone != null && contactPhone!.isNotEmpty)
        'contact_phone': contactPhone,
      'is_default': isDefault,
    };
  }
}

/// Update Address Request
///
/// Request body for updating an existing address.
class UpdateAddressRequest {
  final int addressId;
  final AddressType? type;
  final String? label;
  final String? addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? contactName;
  final String? contactPhone;
  final bool? isDefault;

  const UpdateAddressRequest({
    required this.addressId,
    this.type,
    this.label,
    this.addressLine1,
    this.addressLine2,
    this.landmark,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
    this.contactName,
    this.contactPhone,
    this.isDefault,
  });

  Map<String, dynamic> toJson() {
    return {
      if (type != null) 'type': type!.value,
      if (label != null) 'label': label,
      if (addressLine1 != null) 'address_line_1': addressLine1,
      if (addressLine2 != null) 'address_line_2': addressLine2,
      if (landmark != null) 'landmark': landmark,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (postalCode != null) 'postal_code': postalCode,
      if (country != null) 'country': country,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (contactName != null) 'contact_name': contactName,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (isDefault != null) 'is_default': isDefault,
    };
  }

  bool get hasChanges =>
      type != null ||
      label != null ||
      addressLine1 != null ||
      addressLine2 != null ||
      landmark != null ||
      city != null ||
      state != null ||
      postalCode != null ||
      country != null ||
      latitude != null ||
      longitude != null ||
      contactName != null ||
      contactPhone != null ||
      isDefault != null;
}

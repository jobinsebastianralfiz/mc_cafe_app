/// Add to Cart Request
///
/// Request body for adding an item to cart.
class AddToCartRequest {
  final int productId;
  final int quantity;
  final int? variantId;
  final List<int>? addonIds;
  final String? specialInstructions;

  const AddToCartRequest({
    required this.productId,
    this.quantity = 1,
    this.variantId,
    this.addonIds,
    this.specialInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      if (variantId != null) 'variant_id': variantId,
      if (addonIds != null && addonIds!.isNotEmpty) 'addon_ids': addonIds,
      if (specialInstructions != null && specialInstructions!.isNotEmpty)
        'special_instructions': specialInstructions,
    };
  }
}

/// Update Cart Item Request
///
/// Request body for updating a cart item.
class UpdateCartItemRequest {
  final int cartItemId;
  final int quantity;
  final int? variantId;
  final List<int>? addonIds;
  final String? specialInstructions;

  const UpdateCartItemRequest({
    required this.cartItemId,
    required this.quantity,
    this.variantId,
    this.addonIds,
    this.specialInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      if (variantId != null) 'variant_id': variantId,
      if (addonIds != null) 'addon_ids': addonIds,
      if (specialInstructions != null) 'special_instructions': specialInstructions,
    };
  }
}

/// Apply Coupon Request
///
/// Request body for applying a coupon to cart.
class ApplyCouponRequest {
  final String couponCode;

  const ApplyCouponRequest({
    required this.couponCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'coupon_code': couponCode,
    };
  }
}

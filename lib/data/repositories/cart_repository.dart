import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../models/cart_model.dart';

/// Cart Repository
///
/// Handles all cart related API calls.
/// API Endpoints:
/// - GET /cart - Get cart contents
/// - POST /cart/items - Add item to cart
/// - PUT /cart/items/{id} - Update cart item quantity
/// - DELETE /cart/items/{id} - Remove item from cart
/// - GET /cart/count - Get cart item count
/// - POST /cart/coupon - Apply coupon
/// - DELETE /cart/coupon - Remove coupon
/// - PUT /cart/notes - Update cart notes
/// - DELETE /cart/clear - Clear entire cart
class CartRepository {
  final ApiService _apiService;

  CartRepository({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService.instance;

  /// Get cart contents
  /// GET /cart
  Future<Cart> getCart() async {
    debugPrint('🔵 [CartRepo] getCart called');

    final response = await _apiService.get(ApiConfig.cart);

    debugPrint('🔵 [CartRepo] Response: ${response.data}');

    final data = response['data'];
    if (data == null) {
      debugPrint('🟡 [CartRepo] data is null, returning empty cart');
      return Cart.empty();
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Add item to cart
  /// POST /cart/items
  Future<Cart> addToCart({
    required int productId,
    int? variantId,
    int quantity = 1,
    List<Map<String, dynamic>>? addons,
    String? specialInstructions,
  }) async {
    debugPrint('🔵 [CartRepo] addToCart called');
    debugPrint('🔵 [CartRepo] productId: $productId, variantId: $variantId, quantity: $quantity');

    final body = <String, dynamic>{
      'product_id': productId,
      'quantity': quantity,
    };

    if (variantId != null) {
      body['variant_id'] = variantId;
    }

    if (addons != null && addons.isNotEmpty) {
      body['addons'] = addons;
    }

    if (specialInstructions != null && specialInstructions.isNotEmpty) {
      body['special_instructions'] = specialInstructions;
    }

    debugPrint('🔵 [CartRepo] Body: $body');

    final response = await _apiService.post(
      ApiConfig.cartItems,
      body: body,
    );

    debugPrint('🔵 [CartRepo] Response: ${response.data}');

    final data = response['data'];
    if (data == null) {
      throw Exception('Failed to add item to cart');
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Update cart item quantity
  /// PUT /cart/items/{id}
  Future<Cart> updateCartItem(int cartItemId, int quantity) async {
    debugPrint('🔵 [CartRepo] updateCartItem called');
    debugPrint('🔵 [CartRepo] cartItemId: $cartItemId, quantity: $quantity');

    final response = await _apiService.put(
      '${ApiConfig.cartItemById}/$cartItemId',
      body: {'quantity': quantity},
    );

    debugPrint('🔵 [CartRepo] Response: ${response.data}');

    final data = response['data'];
    if (data == null) {
      throw Exception('Failed to update cart item');
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Remove item from cart
  /// DELETE /cart/items/{id}
  Future<Cart> removeFromCart(int cartItemId) async {
    debugPrint('🔵 [CartRepo] removeFromCart called');
    debugPrint('🔵 [CartRepo] cartItemId: $cartItemId');

    final response = await _apiService.delete(
      '${ApiConfig.cartItemById}/$cartItemId',
    );

    debugPrint('🔵 [CartRepo] Response: ${response.data}');

    final data = response['data'];
    if (data == null) {
      // If no data returned, fetch cart again
      return getCart();
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Get cart item count
  /// GET /cart/count
  Future<int> getCartCount() async {
    debugPrint('🔵 [CartRepo] getCartCount called');

    final response = await _apiService.get(ApiConfig.cartCount);

    debugPrint('🔵 [CartRepo] Response: ${response.data}');

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data['count'] as int? ?? 0;
    }

    return 0;
  }

  /// Apply coupon to cart
  /// POST /cart/coupon
  Future<Cart> applyCoupon(String couponCode) async {
    debugPrint('🔵 [CartRepo] applyCoupon called');
    debugPrint('🔵 [CartRepo] couponCode: $couponCode');

    final response = await _apiService.post(
      ApiConfig.cartCoupon,
      body: {'coupon_code': couponCode},
    );

    debugPrint('🔵 [CartRepo] Response: ${response.data}');

    final data = response['data'];
    if (data == null) {
      throw Exception('Failed to apply coupon');
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Remove coupon from cart
  /// DELETE /cart/coupon
  Future<Cart> removeCoupon() async {
    debugPrint('🔵 [CartRepo] removeCoupon called');

    final response = await _apiService.delete(ApiConfig.cartCoupon);

    debugPrint('🔵 [CartRepo] Response: ${response.data}');

    final data = response['data'];
    if (data == null) {
      return getCart();
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Update cart notes
  /// PUT /cart/notes
  Future<Cart> updateNotes(String notes) async {
    debugPrint('🔵 [CartRepo] updateNotes called');
    debugPrint('🔵 [CartRepo] notes: $notes');

    final response = await _apiService.put(
      ApiConfig.cartNotes,
      body: {'notes': notes},
    );

    debugPrint('🔵 [CartRepo] Response: ${response.data}');

    final data = response['data'];
    if (data == null) {
      return getCart();
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Clear entire cart
  /// DELETE /cart/clear
  Future<bool> clearCart() async {
    debugPrint('🔵 [CartRepo] clearCart called');

    final response = await _apiService.delete(ApiConfig.cartClear);

    debugPrint('🔵 [CartRepo] Response: ${response.data}');

    return response['success'] == true;
  }
}

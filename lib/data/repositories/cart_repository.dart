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
    final response = await _apiService.get(ApiConfig.cart);

    final data = response['data'];
    if (data == null) {
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

    final response = await _apiService.post(
      ApiConfig.cartItems,
      body: body,
    );

    final data = response['data'];
    if (data == null) {
      throw Exception('addToCart: no data in response');
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Update cart item quantity
  /// PUT /cart/items/{id}
  Future<Cart> updateCartItem(int cartItemId, int quantity) async {
    final response = await _apiService.put(
      '${ApiConfig.cartItemById}/$cartItemId',
      body: {'quantity': quantity},
    );

    final data = response['data'];
    if (data == null) {
      throw Exception('Failed to update cart item');
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Remove item from cart
  /// DELETE /cart/items/{id}
  Future<Cart> removeFromCart(int cartItemId) async {
    final response = await _apiService.delete(
      '${ApiConfig.cartItemById}/$cartItemId',
    );

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
    final response = await _apiService.get(ApiConfig.cartCount);

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data['count'] as int? ?? 0;
    }

    return 0;
  }

  /// Apply coupon to cart
  /// POST /cart/coupon
  Future<Cart> applyCoupon(String couponCode) async {
    final response = await _apiService.post(
      ApiConfig.cartCoupon,
      body: {'coupon_code': couponCode},
    );

    final data = response['data'];
    if (data == null) {
      throw Exception('Failed to apply coupon');
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Remove coupon from cart
  /// DELETE /cart/coupon
  Future<Cart> removeCoupon() async {
    final response = await _apiService.delete(ApiConfig.cartCoupon);

    final data = response['data'];
    if (data == null) {
      return getCart();
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Update cart notes
  /// PUT /cart/notes
  Future<Cart> updateNotes(String notes) async {
    final response = await _apiService.put(
      ApiConfig.cartNotes,
      body: {'notes': notes},
    );

    final data = response['data'];
    if (data == null) {
      return getCart();
    }

    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// Clear entire cart
  /// DELETE /cart/clear
  Future<bool> clearCart() async {
    final response = await _apiService.delete(ApiConfig.cartClear);

    return response['success'] == true;
  }
}

/// API Configuration
///
/// Contains all API-related configuration including base URL and endpoints.
/// To change the base URL, modify the [baseUrl] constant.
/// Based on actual MaiCafe API structure.
class ApiConfig {
  ApiConfig._();

  /// Base URL for the API
  /// Change this when switching environments (dev, staging, production)
  static const String baseUrl = 'https://maicafe.workzin.com/api';

  /// Storage URL for media files (images, etc.)
  static const String storageUrl = 'https://maicafe.workzin.com/storage';

  /// API Timeout duration in seconds
  static const int timeoutSeconds = 30;

  /// API Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';

  // ============== Auth Endpoints ==============
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String logout = '/auth/logout';

  // ============== User Endpoints ==============
  static const String profile = '/user/profile';

  // ============== Product Endpoints ==============
  /// GET /categories - List all categories
  static const String categories = '/categories';

  /// GET /categories/{slug} - Get category with products
  /// Use getUrlWithId(categoryBySlug, 'slug-name')
  static const String categoryBySlug = '/categories';

  /// GET /products - List all products (supports query params)
  /// Query params: search, category, category_id, featured, min_price, max_price,
  /// has_variants, in_stock, sort, per_page, page
  static const String products = '/products';

  /// GET /products/{slug} - Get single product details
  /// Use getUrlWithId(productBySlug, 'slug-name')
  static const String productBySlug = '/products';

  // ============== Banner Endpoints ==============
  /// GET /banners - List all active banners
  static const String banners = '/banners';

  /// GET /banners/{id} - Get single banner
  static const String bannerById = '/banners';

  // ============== Cart Endpoints ==============
  /// GET /cart - Get cart contents
  static const String cart = '/cart';

  /// POST /cart/items - Add item to cart
  /// Body: {product_id, variant_id?, quantity, addons?, special_instructions?}
  static const String cartItems = '/cart/items';

  /// PUT /cart/items/{id} - Update cart item quantity
  /// DELETE /cart/items/{id} - Remove item from cart
  static const String cartItemById = '/cart/items';

  /// GET /cart/count - Get cart item count
  static const String cartCount = '/cart/count';

  /// POST /cart/coupon - Apply coupon
  /// DELETE /cart/coupon - Remove coupon
  static const String cartCoupon = '/cart/coupon';

  /// PUT /cart/notes - Update cart notes
  static const String cartNotes = '/cart/notes';

  /// DELETE /cart/clear - Clear entire cart
  static const String cartClear = '/cart/clear';

  // ============== Order Endpoints ==============
  /// GET /orders - List user's orders
  static const String orders = '/orders';

  /// POST /orders/checkout - Place new order
  static const String checkout = '/orders/checkout';

  /// GET /orders/{id} - Get order details
  static const String orderDetails = '/orders';

  /// GET /orders/{id}/track - Track order status
  static const String orderTrack = '/orders';

  /// POST /orders/{id}/cancel - Cancel order
  static const String orderCancel = '/orders';

  /// POST /orders/{id}/reorder - Reorder items to cart
  static const String orderReorder = '/orders';

  /// GET /orders/by-token - Get order by token number
  static const String orderByToken = '/orders/by-token';

  // ============== Wishlist Endpoints ==============
  /// GET /wishlist - Get user's wishlist
  /// POST /wishlist - Add product to wishlist (body: {"product_id": id})
  static const String wishlist = '/wishlist';

  /// DELETE /wishlist/{productId} - Remove product from wishlist
  /// Use: '$wishlistRemove/$productId'
  static const String wishlistRemove = '/wishlist';

  /// DELETE /wishlist/clear - Clear entire wishlist
  static const String wishlistClear = '/wishlist/clear';

  // ============== Address Endpoints ==============
  static const String addresses = '/addresses';
  static const String addAddress = '/addresses/add';
  static const String updateAddress = '/addresses/update';
  static const String deleteAddress = '/addresses/delete';
  static const String setDefaultAddress = '/addresses/default';

  // ============== Coupon Endpoints ==============
  static const String coupons = '/coupons';
  static const String applyCoupon = '/coupons/apply';
  static const String removeCoupon = '/coupons/remove';

  // ============== Notification Endpoints ==============
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // ============== Helper Methods ==============

  /// Get full URL for an endpoint
  static String getUrl(String endpoint) => '$baseUrl$endpoint';

  /// Get URL with slug or ID parameter
  /// Example: getUrlWithId('/products', 'bacon-burger') => /products/bacon-burger
  static String getUrlWithId(String endpoint, dynamic id) =>
      '$baseUrl$endpoint/$id';

  /// Get URL with query parameters
  /// Example: getUrlWithParams('/products', {'category': 'coffee', 'page': 1})
  static String getUrlWithParams(String endpoint, Map<String, dynamic> params) {
    final queryString = params.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    return queryString.isEmpty
        ? '$baseUrl$endpoint'
        : '$baseUrl$endpoint?$queryString';
  }

  /// Get full image URL from relative path
  /// Handles both relative paths (e.g., 'categories/image.png') and full URLs
  /// Example: getImageUrl('categories/image.png') => 'https://maicafe.workzin.com/storage/categories/image.png'
  static String? getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    // Already a full URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Relative path - prepend storage URL
    return '$storageUrl/$imagePath';
  }
}

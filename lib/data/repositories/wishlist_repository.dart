import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../models/models.dart';

/// Wishlist Repository
///
/// Handles all wishlist related API calls.
/// API Endpoints:
/// - GET /wishlist - Get user's wishlist
/// - POST /wishlist - Add product to wishlist
/// - DELETE /wishlist/{productId} - Remove product from wishlist
/// - DELETE /wishlist/clear - Clear entire wishlist
class WishlistRepository {
  final ApiService _apiService;

  WishlistRepository({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService.instance;

  /// Get user's wishlist
  /// GET /wishlist
  Future<Wishlist> getWishlist() async {
    final response = await _apiService.get(ApiConfig.wishlist);

    final data = response['data'];

    // Handle different response formats
    if (data == null) {
      return Wishlist.empty();
    }

    // Response could be: { "data": { "wishlist": [...] } }
    // or: { "data": { "items": [...] } }
    // or: { "data": [...] }
    if (data is List) {
      return Wishlist.fromItems(data);
    }

    if (data is Map<String, dynamic>) {
      // Check for wishlist array
      if (data.containsKey('wishlist') && data['wishlist'] is List) {
        final wishlistItems = data['wishlist'] as List;
        return Wishlist.fromItems(wishlistItems);
      }
      // Check for items array
      if (data.containsKey('items') && data['items'] is List) {
        final items = data['items'] as List;
        return Wishlist.fromItems(items);
      }
      // Check for products array
      if (data.containsKey('products') && data['products'] is List) {
        final products = data['products'] as List;
        return Wishlist.fromItems(products);
      }
      // Try parsing the whole data object
      return Wishlist.fromJson(data);
    }

    return Wishlist.empty();
  }

  /// Add product to wishlist
  /// POST /wishlist with body {"product_id": productId}
  Future<WishlistItem?> addToWishlist(int productId) async {
    final response = await _apiService.post(
      ApiConfig.wishlist,
      body: {'product_id': productId},
    );

    // Response: { "success": true, "data": { "wishlist_item": {...} } }
    final success = response['success'] == true;
    final data = response['data'];

    // Even if success is false (already in wishlist), we might get the item back
    if (data != null && data is Map<String, dynamic>) {
      if (data.containsKey('wishlist_item') && data['wishlist_item'] != null) {
        return WishlistItem.fromJson(data['wishlist_item'] as Map<String, dynamic>);
      }
    }

    if (!success) {
      // Check if it's "already in wishlist" - that's still a success for our purposes
      final message = response['message']?.toString().toLowerCase() ?? '';
      if (message.contains('already')) {
        return null; // Item already exists, not an error
      }
      throw Exception(response['message'] ?? 'Failed to add to wishlist');
    }

    return null;
  }

  /// Remove product from wishlist
  /// DELETE /wishlist/{productId}
  Future<bool> removeFromWishlist(int productId) async {
    final response = await _apiService.delete(
      '${ApiConfig.wishlistRemove}/$productId',
    );

    return response['success'] == true;
  }

  /// Clear entire wishlist
  /// DELETE /wishlist/clear
  Future<bool> clearWishlist() async {
    final response = await _apiService.delete(ApiConfig.wishlistClear);

    return response['success'] == true;
  }

  /// Check if product is in wishlist
  Future<bool> isInWishlist(int productId) async {
    try {
      final wishlist = await getWishlist();
      return wishlist.containsProduct(productId);
    } catch (e) {
      return false;
    }
  }

  /// Get wishlist item count
  /// GET /wishlist/count
  Future<int> getWishlistCount() async {
    try {
      final response = await _apiService.get(ApiConfig.wishlistCount);
      final data = response['data'];

      if (data is Map<String, dynamic> && data.containsKey('count')) {
        return data['count'] as int;
      }
      if (data is int) {
        return data;
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }
}

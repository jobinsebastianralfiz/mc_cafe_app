import 'package:flutter/foundation.dart';

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
    debugPrint('🔵 [WishlistRepo] getWishlist called');
    debugPrint('🔵 [WishlistRepo] Endpoint: GET ${ApiConfig.wishlist}');

    final response = await _apiService.get(ApiConfig.wishlist);

    debugPrint('🔵 [WishlistRepo] Response: ${response.data}');

    final data = response['data'];

    debugPrint('🔵 [WishlistRepo] data: $data');
    debugPrint('🔵 [WishlistRepo] data type: ${data.runtimeType}');

    // Handle different response formats
    if (data == null) {
      debugPrint('🟡 [WishlistRepo] data is null, returning empty wishlist');
      return Wishlist.empty();
    }

    // Response could be: { "data": { "wishlist": [...] } }
    // or: { "data": { "items": [...] } }
    // or: { "data": [...] }
    if (data is List) {
      debugPrint('🟢 [WishlistRepo] data is List with ${data.length} items');
      return Wishlist.fromItems(data);
    }

    if (data is Map<String, dynamic>) {
      debugPrint('🔵 [WishlistRepo] data is Map with keys: ${data.keys.toList()}');

      // Check for wishlist array
      if (data.containsKey('wishlist') && data['wishlist'] is List) {
        final wishlistItems = data['wishlist'] as List;
        debugPrint('🟢 [WishlistRepo] Found wishlist key with ${wishlistItems.length} items');
        return Wishlist.fromItems(wishlistItems);
      }
      // Check for items array
      if (data.containsKey('items') && data['items'] is List) {
        final items = data['items'] as List;
        debugPrint('🟢 [WishlistRepo] Found items key with ${items.length} items');
        return Wishlist.fromItems(items);
      }
      // Check for products array
      if (data.containsKey('products') && data['products'] is List) {
        final products = data['products'] as List;
        debugPrint('🟢 [WishlistRepo] Found products key with ${products.length} items');
        return Wishlist.fromItems(products);
      }
      // Try parsing the whole data object
      debugPrint('🟡 [WishlistRepo] No known key found, trying to parse whole data object');
      return Wishlist.fromJson(data);
    }

    debugPrint('🟡 [WishlistRepo] Unknown data format, returning empty wishlist');
    return Wishlist.empty();
  }

  /// Add product to wishlist
  /// POST /wishlist with body {"product_id": productId}
  Future<WishlistItem?> addToWishlist(int productId) async {
    debugPrint('🔵 [WishlistRepo] addToWishlist called for productId: $productId');
    debugPrint('🔵 [WishlistRepo] Endpoint: POST ${ApiConfig.wishlist}');
    debugPrint('🔵 [WishlistRepo] Body: {"product_id": $productId}');

    final response = await _apiService.post(
      ApiConfig.wishlist,
      body: {'product_id': productId},
    );

    debugPrint('🔵 [WishlistRepo] Response: ${response.data}');

    // Response: { "success": true, "data": { "wishlist_item": {...} } }
    final success = response['success'] == true;
    final data = response['data'];

    debugPrint('🔵 [WishlistRepo] success: $success, data: $data');

    // Even if success is false (already in wishlist), we might get the item back
    if (data != null && data is Map<String, dynamic>) {
      if (data.containsKey('wishlist_item') && data['wishlist_item'] != null) {
        debugPrint('🟢 [WishlistRepo] Got wishlist_item from response');
        return WishlistItem.fromJson(data['wishlist_item'] as Map<String, dynamic>);
      }
    }

    if (!success) {
      // Check if it's "already in wishlist" - that's still a success for our purposes
      final message = response['message']?.toString().toLowerCase() ?? '';
      debugPrint('🟡 [WishlistRepo] Not success. Message: $message');
      if (message.contains('already')) {
        debugPrint('🟡 [WishlistRepo] Already in wishlist - returning null (success)');
        return null; // Item already exists, not an error
      }
      debugPrint('🔴 [WishlistRepo] Throwing exception: ${response['message']}');
      throw Exception(response['message'] ?? 'Failed to add to wishlist');
    }

    debugPrint('🟢 [WishlistRepo] Success, returning null');
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
}

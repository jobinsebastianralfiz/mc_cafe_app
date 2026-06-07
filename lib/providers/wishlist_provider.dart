import 'package:flutter/foundation.dart';

import '../core/enums/app_enums.dart';
import '../core/exceptions/api_exception.dart';
import '../data/models/models.dart';
import '../data/repositories/wishlist_repository.dart';

/// Wishlist Provider
///
/// Manages wishlist state and operations.
class WishlistProvider with ChangeNotifier {
  final WishlistRepository _repository;

  WishlistProvider({
    WishlistRepository? repository,
  }) : _repository = repository ?? WishlistRepository();

  // State
  Wishlist _wishlist = Wishlist.empty();
  LoadingStatus _status = LoadingStatus.initial;
  String? _errorMessage;

  // Track which products are in the wishlist for quick lookup
  final Set<int> _wishlistProductIds = {};

  // Getters
  Wishlist get wishlist => _wishlist;
  List<WishlistItem> get items => _wishlist.items;
  LoadingStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == LoadingStatus.loading;
  bool get isEmpty => _wishlist.isEmpty;
  int get itemCount => _wishlist.itemCount;

  /// Check if a product is in the wishlist
  bool isInWishlist(int productId) {
    return _wishlistProductIds.contains(productId);
  }

  /// Load wishlist from API
  Future<void> loadWishlist({bool forceRefresh = false}) async {
    if (_status == LoadingStatus.loading && !forceRefresh) {
      return;
    }
    if (_status == LoadingStatus.success && !forceRefresh) {
      return;
    }

    _status = LoadingStatus.loading;
    _clearError();
    notifyListeners();

    try {
      _wishlist = await _repository.getWishlist();
      _updateProductIds();
      _status = LoadingStatus.success;
    } on ApiException catch (e) {
      _setError(e.message);
      _status = LoadingStatus.error;
    } catch (e) {
      _setError('Failed to load wishlist');
      _status = LoadingStatus.error;
    }

    notifyListeners();
  }

  /// Add product to wishlist
  Future<bool> addToWishlist(Product product) async {
    // Optimistically update UI
    final tempItem = WishlistItem(
      id: DateTime.now().millisecondsSinceEpoch,
      productId: product.id,
      productName: product.name,
      productImage: product.image,
      price: product.priceAsDouble,
      product: product,
      addedAt: DateTime.now(),
    );

    _wishlist = _wishlist.copyWith(
      items: [..._wishlist.items, tempItem],
    );
    _wishlistProductIds.add(product.id);
    notifyListeners();

    try {
      // Repository returns WishlistItem? on success, or throws on error
      // null return means item already exists (which is still success for us)
      await _repository.addToWishlist(product.id);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _removeFromLocalWishlist(product.id);
      return false;
    } catch (e) {
      // Check if it's an "already in wishlist" error - treat as success
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already')) {
        return true;
      }
      _setError('Failed to add to wishlist');
      _removeFromLocalWishlist(product.id);
      return false;
    }
  }

  /// Remove product from wishlist
  Future<bool> removeFromWishlist(int productId) async {
    // Store the item for potential rollback
    final removedItem = _wishlist.items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => WishlistItem(
        id: 0,
        productId: productId,
        productName: '',
        price: 0,
      ),
    );
    final removedIndex = _wishlist.items.indexWhere(
      (item) => item.productId == productId,
    );

    // Optimistically update UI
    _removeFromLocalWishlist(productId);

    try {
      final success = await _repository.removeFromWishlist(productId);
      if (!success) {
        // Revert on failure
        _addToLocalWishlist(removedItem, removedIndex);
        return false;
      }
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _addToLocalWishlist(removedItem, removedIndex);
      return false;
    } catch (e) {
      _setError('Failed to remove from wishlist');
      _addToLocalWishlist(removedItem, removedIndex);
      return false;
    }
  }

  /// Toggle product in wishlist
  Future<bool> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      return removeFromWishlist(product.id);
    } else {
      return addToWishlist(product);
    }
  }

  /// Clear wishlist (local only, for logout)
  void clearWishlist() {
    _wishlist = Wishlist.empty();
    _wishlistProductIds.clear();
    _status = LoadingStatus.initial;
    _clearError();
    notifyListeners();
  }

  /// Get wishlist count from API
  Future<int> fetchWishlistCount() async {
    try {
      final count = await _repository.getWishlistCount();
      return count;
    } catch (e) {
      return itemCount; // Return local count as fallback
    }
  }

  // Private methods

  void _removeFromLocalWishlist(int productId) {
    _wishlist = _wishlist.copyWith(
      items: _wishlist.items.where((item) => item.productId != productId).toList(),
    );
    _wishlistProductIds.remove(productId);
    notifyListeners();
  }

  void _addToLocalWishlist(WishlistItem item, int index) {
    final items = [..._wishlist.items];
    if (index >= 0 && index < items.length) {
      items.insert(index, item);
    } else {
      items.add(item);
    }
    _wishlist = _wishlist.copyWith(items: items);
    _wishlistProductIds.add(item.productId);
    notifyListeners();
  }

  void _updateProductIds() {
    _wishlistProductIds.clear();
    for (final item in _wishlist.items) {
      _wishlistProductIds.add(item.productId);
    }
  }

  void _setError(String message) {
    _errorMessage = message;
  }

  void _clearError() {
    _errorMessage = null;
  }
}

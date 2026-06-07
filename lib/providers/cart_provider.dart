import 'package:flutter/foundation.dart';

import '../core/enums/app_enums.dart';
import '../core/exceptions/api_exception.dart';
import '../data/models/cart_model.dart';
import '../data/models/product_model.dart';
import '../data/repositories/cart_repository.dart';

/// Cart Provider
///
/// Manages shopping cart state using ChangeNotifier for Provider.
/// Connected to Cart API for persistent cart management.
class CartProvider extends ChangeNotifier {
  final CartRepository _repository;

  CartProvider({
    CartRepository? repository,
  }) : _repository = repository ?? CartRepository();

  // ============== State ==============

  Cart _cart = Cart.empty();
  LoadingStatus _status = LoadingStatus.initial;
  String? _errorMessage;

  // ============== Getters ==============

  Cart get cart => _cart;
  List<CartItem> get items => _cart.items;
  LoadingStatus get status => _status;
  String? get errorMessage => _errorMessage;

  bool get isEmpty => _cart.isEmpty;
  bool get isNotEmpty => _cart.isNotEmpty;
  int get itemCount => _cart.itemCount;
  int get uniqueItemCount => _cart.uniqueItemCount;
  double get subtotal => _cart.subtotal;
  double get total => _cart.total;
  double get tax => _cart.tax;
  double get discount => _cart.discount;
  String get currencySymbol => _cart.currency.symbol;

  bool get isLoading => _status == LoadingStatus.loading;

  // ============== Load Cart ==============

  /// Load cart from API
  Future<void> loadCart({bool forceRefresh = false}) async {
    if (_status == LoadingStatus.loading && !forceRefresh) return;
    if (_status == LoadingStatus.success && !forceRefresh) return;

    _status = LoadingStatus.loading;
    _clearError();
    notifyListeners();

    try {
      _cart = await _repository.getCart();
      _status = LoadingStatus.success;
    } on ApiException catch (e) {
      _setError(e.message);
      _status = LoadingStatus.error;
    } catch (e) {
      _setError('Failed to load cart');
      _status = LoadingStatus.error;
    }

    notifyListeners();
  }

  // ============== Add to Cart ==============

  /// Add product to cart
  Future<bool> addToCart({
    required Product product,
    int quantity = 1,
    ProductVariant? variant,
    List<Addon>? addons,
    String? specialInstructions,
  }) async {
    _status = LoadingStatus.loading;
    _clearError();
    notifyListeners();

    try {
      // Prepare addons for API
      List<Map<String, dynamic>>? addonsData;
      if (addons != null && addons.isNotEmpty) {
        addonsData = addons.map((addon) => {
          'id': addon.id,
          'quantity': 1,
        }).toList();
      }

      _cart = await _repository.addToCart(
        productId: product.id,
        variantId: variant?.id,
        quantity: quantity,
        addons: addonsData,
        specialInstructions: specialInstructions,
      );

      _status = LoadingStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError('${e.message} [${e.statusCode}]');
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _setError('Failed to add item to cart: $e');
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ============== Update Quantity ==============

  /// Update cart item quantity
  Future<bool> updateQuantity(int cartItemId, int quantity) async {
    if (quantity < 1) {
      return removeFromCart(cartItemId);
    }

    _status = LoadingStatus.loading;
    notifyListeners();

    try {
      _cart = await _repository.updateCartItem(cartItemId, quantity);
      _status = LoadingStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _setError('Failed to update quantity');
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ============== Remove from Cart ==============

  /// Remove item from cart
  Future<bool> removeFromCart(int cartItemId) async {
    _status = LoadingStatus.loading;
    notifyListeners();

    try {
      _cart = await _repository.removeFromCart(cartItemId);
      _status = LoadingStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _setError('Failed to remove item');
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ============== Clear Cart ==============

  /// Clear all items from cart
  Future<bool> clearCart() async {
    _status = LoadingStatus.loading;
    notifyListeners();

    try {
      final success = await _repository.clearCart();
      if (success) {
        _cart = Cart.empty();
      }
      _status = LoadingStatus.success;
      notifyListeners();
      return success;
    } on ApiException catch (e) {
      _setError(e.message);
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _setError('Failed to clear cart');
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ============== Coupon Methods ==============

  /// Apply coupon to cart
  Future<bool> applyCoupon(String couponCode) async {
    _status = LoadingStatus.loading;
    notifyListeners();

    try {
      _cart = await _repository.applyCoupon(couponCode);
      _status = LoadingStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _setError('Failed to apply coupon');
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Remove coupon from cart
  Future<bool> removeCoupon() async {
    _status = LoadingStatus.loading;
    notifyListeners();

    try {
      _cart = await _repository.removeCoupon();
      _status = LoadingStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _setError('Failed to remove coupon');
      _status = LoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ============== Notes Methods ==============

  /// Update cart notes
  Future<bool> updateNotes(String notes) async {
    try {
      _cart = await _repository.updateNotes(notes);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to update notes');
      return false;
    }
  }

  // ============== Helper Methods ==============

  /// Check if product is in cart
  bool isInCart(int productId) {
    return _cart.items.any((item) => item.productId == productId);
  }

  /// Get cart item by product ID
  CartItem? getCartItem(int productId) {
    try {
      return _cart.items.firstWhere((item) => item.productId == productId);
    } catch (_) {
      return null;
    }
  }

  /// Get cart item by cart item ID
  CartItem? getCartItemById(int cartItemId) {
    try {
      return _cart.items.firstWhere((item) => item.id == cartItemId);
    } catch (_) {
      return null;
    }
  }

  // ============== Private Helpers ==============

  void _setError(String message) {
    _errorMessage = message;
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset cart state (for logout)
  void resetCart() {
    _cart = Cart.empty();
    _status = LoadingStatus.initial;
    _clearError();
    notifyListeners();
  }
}

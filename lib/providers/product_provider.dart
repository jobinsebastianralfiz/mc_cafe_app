import 'package:flutter/foundation.dart' hide Category;

import '../core/enums/app_enums.dart';
import '../core/exceptions/api_exception.dart';
import '../data/models/models.dart';
import '../data/repositories/product_repository.dart';

/// Product Provider
///
/// Manages product, category, and banner state using ChangeNotifier for Provider.
class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository;

  ProductProvider({ProductRepository? repository})
      : _repository = repository ?? ProductRepository();

  // ============== State ==============

  // Categories
  List<Category> _categories = [];
  LoadingStatus _categoriesStatus = LoadingStatus.initial;

  // Products
  List<Product> _products = [];
  LoadingStatus _productsStatus = LoadingStatus.initial;
  Pagination? _productsPagination;

  // Featured products
  List<Product> _featuredProducts = [];
  LoadingStatus _featuredStatus = LoadingStatus.initial;

  // Current product detail
  Product? _selectedProduct;
  LoadingStatus _productDetailStatus = LoadingStatus.initial;

  // Banners
  List<Banner> _banners = [];
  LoadingStatus _bannersStatus = LoadingStatus.initial;

  // Search
  List<Product> _searchResults = [];
  LoadingStatus _searchStatus = LoadingStatus.initial;
  String _searchQuery = '';

  // Error
  String? _errorMessage;

  // ============== Getters ==============

  // Categories
  List<Category> get categories => _categories;
  LoadingStatus get categoriesStatus => _categoriesStatus;
  bool get isCategoriesLoading => _categoriesStatus == LoadingStatus.loading;

  // Products
  List<Product> get products => _products;
  LoadingStatus get productsStatus => _productsStatus;
  Pagination? get productsPagination => _productsPagination;
  bool get isProductsLoading => _productsStatus == LoadingStatus.loading;
  bool get hasMoreProducts => _productsPagination?.hasMore ?? false;

  // Featured
  List<Product> get featuredProducts => _featuredProducts;
  LoadingStatus get featuredStatus => _featuredStatus;
  bool get isFeaturedLoading => _featuredStatus == LoadingStatus.loading;

  // Product detail
  Product? get selectedProduct => _selectedProduct;
  LoadingStatus get productDetailStatus => _productDetailStatus;
  bool get isProductDetailLoading => _productDetailStatus == LoadingStatus.loading;

  // Banners
  List<Banner> get banners => _banners;
  LoadingStatus get bannersStatus => _bannersStatus;
  bool get isBannersLoading => _bannersStatus == LoadingStatus.loading;

  // Search
  List<Product> get searchResults => _searchResults;
  LoadingStatus get searchStatus => _searchStatus;
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchStatus == LoadingStatus.loading;

  // Error
  String? get errorMessage => _errorMessage;

  // ============== Category Methods ==============

  /// Load all categories
  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (_categoriesStatus == LoadingStatus.loading) return;
    if (_categories.isNotEmpty && !forceRefresh) return;

    _categoriesStatus = LoadingStatus.loading;
    _clearError();
    notifyListeners();

    try {
      _categories = await _repository.getCategories();
      _categoriesStatus = LoadingStatus.success;
    } on ApiException catch (e) {
      _setError(e.message);
      _categoriesStatus = LoadingStatus.error;
    } catch (e) {
      _setError('Failed to load categories');
      _categoriesStatus = LoadingStatus.error;
    }

    notifyListeners();
  }

  /// Get category by slug with products
  Future<CategoryWithProducts?> getCategoryWithProducts(
    String slug, {
    int page = 1,
  }) async {
    try {
      return await _repository.getCategoryBySlug(slug, page: page);
    } on ApiException catch (e) {
      _setError(e.message);
      return null;
    } catch (e) {
      _setError('Failed to load category');
      return null;
    }
  }

  // ============== Product Methods ==============

  /// Load products with optional filters
  Future<void> loadProducts({
    String? category,
    int? categoryId,
    bool? featured,
    double? minPrice,
    double? maxPrice,
    String? sort,
    bool refresh = false,
  }) async {
    if (_productsStatus == LoadingStatus.loading && !refresh) return;

    final page = refresh ? 1 : (_productsPagination?.nextPage ?? 1);

    if (!refresh && _productsStatus == LoadingStatus.loading) return;

    _productsStatus = LoadingStatus.loading;
    if (refresh) {
      _products = [];
      _productsPagination = null;
    }
    _clearError();
    notifyListeners();

    try {
      final response = await _repository.getProducts(
        category: category,
        categoryId: categoryId,
        featured: featured,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sort: sort,
        page: page,
      );

      if (refresh) {
        _products = response.products;
      } else {
        _products = [..._products, ...response.products];
      }
      _productsPagination = response.pagination;
      _productsStatus = LoadingStatus.success;
    } on ApiException catch (e) {
      _setError(e.message);
      _productsStatus = LoadingStatus.error;
    } catch (e) {
      _setError('Failed to load products');
      _productsStatus = LoadingStatus.error;
    }

    notifyListeners();
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts({
    String? category,
    int? categoryId,
    bool? featured,
    String? sort,
  }) async {
    if (!hasMoreProducts) return;
    if (_productsStatus == LoadingStatus.loading) return;

    await loadProducts(
      category: category,
      categoryId: categoryId,
      featured: featured,
      sort: sort,
      refresh: false,
    );
  }

  /// Load featured products
  Future<void> loadFeaturedProducts({bool forceRefresh = false}) async {
    if (_featuredStatus == LoadingStatus.loading) return;
    if (_featuredProducts.isNotEmpty && !forceRefresh) return;

    _featuredStatus = LoadingStatus.loading;
    _clearError();
    notifyListeners();

    try {
      _featuredProducts = await _repository.getFeaturedProducts();
      _featuredStatus = LoadingStatus.success;
    } on ApiException catch (e) {
      _setError(e.message);
      _featuredStatus = LoadingStatus.error;
    } catch (e) {
      _setError('Failed to load featured products');
      _featuredStatus = LoadingStatus.error;
    }

    notifyListeners();
  }

  /// Get product by slug
  Future<void> loadProductDetail(String slug) async {
    _productDetailStatus = LoadingStatus.loading;
    _selectedProduct = null;
    _clearError();
    notifyListeners();

    try {
      _selectedProduct = await _repository.getProductBySlug(slug);
      _productDetailStatus = LoadingStatus.success;
    } on ApiException catch (e) {
      _setError(e.message);
      _productDetailStatus = LoadingStatus.error;
    } catch (e) {
      _setError('Failed to load product details');
      _productDetailStatus = LoadingStatus.error;
    }

    notifyListeners();
  }

  /// Clear selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    _productDetailStatus = LoadingStatus.initial;
    notifyListeners();
  }

  /// Get product by slug (returns Product directly)
  Future<Product> getProductBySlug(String slug) async {
    return await _repository.getProductBySlug(slug);
  }

  // ============== Banner Methods ==============

  /// Load banners
  Future<void> loadBanners({bool forceRefresh = false}) async {
    if (_bannersStatus == LoadingStatus.loading) return;
    if (_banners.isNotEmpty && !forceRefresh) return;

    _bannersStatus = LoadingStatus.loading;
    _clearError();
    notifyListeners();

    try {
      _banners = await _repository.getBanners();
      _bannersStatus = LoadingStatus.success;
    } on ApiException catch (e) {
      _setError(e.message);
      _bannersStatus = LoadingStatus.error;
    } catch (e) {
      _setError('Failed to load banners');
      _bannersStatus = LoadingStatus.error;
    }

    notifyListeners();
  }

  // ============== Search Methods ==============

  /// Search products
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    _searchQuery = query;
    _searchStatus = LoadingStatus.loading;
    _clearError();
    notifyListeners();

    try {
      final response = await _repository.searchProducts(query);
      _searchResults = response.products;
      _searchStatus = LoadingStatus.success;
    } on ApiException catch (e) {
      _setError(e.message);
      _searchStatus = LoadingStatus.error;
    } catch (e) {
      _setError('Search failed');
      _searchStatus = LoadingStatus.error;
    }

    notifyListeners();
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    _searchStatus = LoadingStatus.initial;
    notifyListeners();
  }

  // ============== Home Screen Data ==============

  /// Load all data needed for home screen
  Future<void> loadHomeData({bool forceRefresh = false}) async {
    await Future.wait([
      loadCategories(forceRefresh: forceRefresh),
      loadFeaturedProducts(forceRefresh: forceRefresh),
      loadBanners(forceRefresh: forceRefresh),
    ]);
  }

  // ============== Private Helpers ==============

  void _setError(String message) {
    _errorMessage = message;
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message (can be called from UI)
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

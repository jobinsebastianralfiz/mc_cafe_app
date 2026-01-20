import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../models/models.dart';

/// Product Repository
///
/// Handles all product, category, and banner related API calls.
class ProductRepository {
  final ApiService _apiService;

  ProductRepository({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService.instance;

  // ============== Categories ==============

  /// Get all categories
  Future<List<Category>> getCategories() async {
    final response = await _apiService.get(ApiConfig.categories);

    final data = response['data'] as Map<String, dynamic>;
    final categoriesJson = data['categories'] as List;

    return categoriesJson
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get category by slug with its products
  Future<CategoryWithProducts> getCategoryBySlug(
    String slug, {
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _apiService.get(
      '${ApiConfig.categoryBySlug}/$slug',
      queryParams: {
        'page': page,
        'per_page': perPage,
      },
    );

    final data = response['data'] as Map<String, dynamic>;

    final category = Category.fromJson(data['category'] as Map<String, dynamic>);
    final productsJson = data['products'] as List;
    final products = productsJson
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();

    Pagination? pagination;
    if (data['pagination'] != null) {
      pagination = Pagination.fromJson(data['pagination'] as Map<String, dynamic>);
    }

    return CategoryWithProducts(
      category: category,
      products: products,
      pagination: pagination,
    );
  }

  // ============== Products ==============

  /// Get all products with optional filters
  Future<ProductsResponse> getProducts({
    String? search,
    String? category,
    int? categoryId,
    bool? featured,
    double? minPrice,
    double? maxPrice,
    bool? hasVariants,
    bool? inStock,
    String? sort,
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParams = <String, dynamic>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
      if (categoryId != null) 'category_id': categoryId,
      if (featured != null) 'featured': featured,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (hasVariants != null) 'has_variants': hasVariants,
      if (inStock != null) 'in_stock': inStock,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      'page': page,
      'per_page': perPage,
    };

    final response = await _apiService.get(
      ApiConfig.products,
      queryParams: queryParams,
    );

    final data = response['data'] as Map<String, dynamic>;
    final productsJson = data['products'] as List;
    final products = productsJson
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();

    Pagination? pagination;
    if (data['pagination'] != null) {
      pagination = Pagination.fromJson(data['pagination'] as Map<String, dynamic>);
    }

    return ProductsResponse(
      products: products,
      pagination: pagination,
    );
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    final response = await getProducts(featured: true, perPage: limit);
    return response.products;
  }

  /// Search products
  Future<ProductsResponse> searchProducts(
    String query, {
    int page = 1,
    int perPage = 15,
  }) async {
    return getProducts(search: query, page: page, perPage: perPage);
  }

  /// Get product by slug
  Future<Product> getProductBySlug(String slug) async {
    final response = await _apiService.get('${ApiConfig.productBySlug}/$slug');

    final data = response['data'] as Map<String, dynamic>;
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  // ============== Banners ==============

  /// Get all active banners
  Future<List<Banner>> getBanners() async {
    final response = await _apiService.get(ApiConfig.banners);

    final data = response['data'] as Map<String, dynamic>;
    final bannersJson = data['banners'] as List;

    return bannersJson
        .map((e) => Banner.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get banner by ID
  Future<Banner> getBannerById(int id) async {
    final response = await _apiService.get('${ApiConfig.bannerById}/$id');

    final data = response['data'] as Map<String, dynamic>;
    return Banner.fromJson(data['banner'] as Map<String, dynamic>);
  }
}

/// Response wrapper for category with products
class CategoryWithProducts {
  final Category category;
  final List<Product> products;
  final Pagination? pagination;

  const CategoryWithProducts({
    required this.category,
    required this.products,
    this.pagination,
  });
}

/// Response wrapper for products list
class ProductsResponse {
  final List<Product> products;
  final Pagination? pagination;

  const ProductsResponse({
    required this.products,
    this.pagination,
  });
}

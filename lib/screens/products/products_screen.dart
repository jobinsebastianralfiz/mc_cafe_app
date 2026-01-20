import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/pattern_background.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_loading.dart';

class ProductsScreen extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialCategoryName;

  const ProductsScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  int _currentNavIndex = 0;
  int _selectedCategoryIndex = 0; // 0 means "All"
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initializeData() {
    final productProvider = context.read<ProductProvider>();

    // Load categories if not loaded
    if (productProvider.categories.isEmpty) {
      productProvider.loadCategories();
    }

    // Check if we have initial category from arguments
    if (widget.initialCategoryId != null) {
      // Find the category index
      final categories = productProvider.categories;
      final index = categories.indexWhere((c) => c.id == widget.initialCategoryId);
      if (index >= 0) {
        setState(() {
          _selectedCategoryIndex = index + 1; // +1 because 0 is "All"
        });
      }
      productProvider.loadProducts(categoryId: widget.initialCategoryId, refresh: true);
    } else {
      // Load all products
      productProvider.loadProducts(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() {
    final productProvider = context.read<ProductProvider>();
    if (productProvider.hasMoreProducts &&
        productProvider.productsStatus != LoadingStatus.loading) {
      final categories = productProvider.categories;
      int? categoryId;
      if (_selectedCategoryIndex > 0 && _selectedCategoryIndex <= categories.length) {
        categoryId = categories[_selectedCategoryIndex - 1].id;
      }
      productProvider.loadProducts(categoryId: categoryId);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final productProvider = context.read<ProductProvider>();
      if (query.trim().isEmpty) {
        setState(() => _isSearchMode = false);
        productProvider.clearSearch();
        // Reload current category products
        _loadCategoryProducts();
      } else {
        setState(() => _isSearchMode = true);
        productProvider.searchProducts(query.trim());
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _isSearchMode = false);
    final productProvider = context.read<ProductProvider>();
    productProvider.clearSearch();
    _loadCategoryProducts();
  }

  void _loadCategoryProducts() {
    final productProvider = context.read<ProductProvider>();
    final categories = productProvider.categories;

    if (_selectedCategoryIndex == 0) {
      productProvider.loadProducts(refresh: true);
    } else if (_selectedCategoryIndex <= categories.length) {
      productProvider.loadProducts(
        categoryId: categories[_selectedCategoryIndex - 1].id,
        refresh: true,
      );
    }
  }

  void _onCategorySelected(int index) {
    if (_selectedCategoryIndex == index) return;

    setState(() {
      _selectedCategoryIndex = index;
      _isSearchMode = false;
    });
    _searchController.clear();

    final productProvider = context.read<ProductProvider>();
    productProvider.clearSearch();

    final categories = productProvider.categories;
    if (index == 0) {
      productProvider.loadProducts(refresh: true);
    } else if (index <= categories.length) {
      productProvider.loadProducts(
        categoryId: categories[index - 1].id,
        refresh: true,
      );
    }
  }

  void _onNavTap(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, AppRoutes.cart);
      return;
    }
    setState(() {
      _currentNavIndex = index;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        onApply: (minPrice, maxPrice, sortBy) {
          final productProvider = context.read<ProductProvider>();
          final categories = productProvider.categories;

          int? categoryId;
          if (_selectedCategoryIndex > 0 && _selectedCategoryIndex <= categories.length) {
            categoryId = categories[_selectedCategoryIndex - 1].id;
          }

          productProvider.loadProducts(
            categoryId: categoryId,
            minPrice: minPrice,
            maxPrice: maxPrice,
            sort: sortBy,
            refresh: true,
          );

          setState(() => _isSearchMode = false);
          _searchController.clear();
        },
      ),
    );
  }

  String get _sectionTitle {
    if (_isSearchMode) {
      return 'Search Results';
    }

    final productProvider = context.read<ProductProvider>();
    final categories = productProvider.categories;

    if (_selectedCategoryIndex == 0) {
      return 'All Products';
    } else if (_selectedCategoryIndex <= categories.length) {
      return categories[_selectedCategoryIndex - 1].name;
    }
    return 'Products';
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      body: PatternBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadCategoryProducts();
                  },
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingL,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildSearchBar(),
                          const SizedBox(height: 20),
                          _buildCategoryChips(),
                          const SizedBox(height: 24),
                          _buildSectionTitle(),
                          const SizedBox(height: 16),
                          _buildProductsGrid(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        cartCount: cartProvider.itemCount,
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textHeading,
                size: 18,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Products',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.wishlist);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite_border,
                color: AppColors.textHeading,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: AppColors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 14,
                        color: AppColors.grey.withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: _isSearchMode
                          ? GestureDetector(
                              onTap: _clearSearch,
                              child: const Icon(
                                Icons.close,
                                color: AppColors.grey,
                                size: 18,
                              ),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _showFilterBottomSheet,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.tune,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final productProvider = context.watch<ProductProvider>();
    final categories = productProvider.categories;
    final isLoading = productProvider.categoriesStatus == LoadingStatus.loading;

    return SizedBox(
      height: 36,
      child: isLoading && categories.isEmpty
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => const ShimmerChip(),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1, // +1 for "All"
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AnimatedListItem(
                    index: index,
                    delay: const Duration(milliseconds: 60),
                    child: CategoryChip(
                      label: 'All',
                      isSelected: _selectedCategoryIndex == 0,
                      onTap: () => _onCategorySelected(0),
                    ),
                  );
                }
                final category = categories[index - 1];
                return AnimatedListItem(
                  index: index,
                  delay: const Duration(milliseconds: 60),
                  child: CategoryChip(
                    label: category.name,
                    isSelected: _selectedCategoryIndex == index,
                    onTap: () => _onCategorySelected(index),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSectionTitle() {
    return Text(
      _sectionTitle,
      style: const TextStyle(
        fontFamily: 'Sora',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textHeading,
      ),
    );
  }

  Widget _buildProductsGrid() {
    final productProvider = context.watch<ProductProvider>();

    // Determine which products to show
    final products = _isSearchMode
        ? productProvider.searchResults
        : productProvider.products;
    final isLoading = _isSearchMode
        ? productProvider.searchStatus == LoadingStatus.loading
        : productProvider.productsStatus == LoadingStatus.loading;

    if (isLoading && products.isEmpty) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ShimmerProductCard(),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _isSearchMode ? 'No products found' : 'No products available',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              if (_isSearchMode) ...[
                const SizedBox(height: 8),
                const Text(
                  'Try a different search term',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ScaleInWidget(
              delay: Duration(milliseconds: 50 * (index % 6)),
              child: ProductCard(
                imageUrl: ApiConfig.getImageUrl(product.image),
                name: product.name,
                description: product.shortDescription,
                rating: 4.5,
                price: product.priceAsDouble,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.productDetail,
                    arguments: {
                      'slug': product.slug,
                      'product': product,
                    },
                  );
                },
                onAddTap: () {
                  final cartProvider = context.read<CartProvider>();
                  cartProvider.addToCart(product: product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            );
          },
        ),
        // Loading indicator for pagination
        if (isLoading && products.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

/// Filter Bottom Sheet Widget
class _FilterBottomSheet extends StatefulWidget {
  final Function(double? minPrice, double? maxPrice, String? sortBy) onApply;

  const _FilterBottomSheet({required this.onApply});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  RangeValues _priceRange = const RangeValues(0, 50);
  String _selectedSort = 'newest';

  final List<Map<String, String>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First'},
    {'value': 'oldest', 'label': 'Oldest First'},
    {'value': 'price_low', 'label': 'Price: Low to High'},
    {'value': 'price_high', 'label': 'Price: High to Low'},
    {'value': 'name_asc', 'label': 'Name: A to Z'},
    {'value': 'name_desc', 'label': 'Name: Z to A'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _priceRange = const RangeValues(0, 50);
                    _selectedSort = 'newest';
                  });
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Price Range
          const Text(
            'Price Range',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '£${_priceRange.start.toInt()}',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '£${_priceRange.end.toInt()}',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          const SizedBox(height: 24),

          // Sort By
          const Text(
            'Sort By',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((option) {
              final isSelected = _selectedSort == option['value'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSort = option['value']!;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    option['label']!,
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(
                  _priceRange.start,
                  _priceRange.end,
                  _selectedSort,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Apply Filter',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

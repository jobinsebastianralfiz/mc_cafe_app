import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pattern_background.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductDetailScreen({super.key, this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedVariantIndex = 0; // Default to first variant
  final Set<int> _selectedExtras = {};
  bool _isAddedToCart = false;

  // Fallback sizes when product has no variants
  final List<String> _fallbackSizes = ['S', 'M', 'L'];

  final List<Map<String, dynamic>> _extras = [
    {'name': 'Extra Shot', 'price': 0.50},
    {'name': 'Almond Milk', 'price': 0.60},
    {'name': 'Caramel Syrup', 'price': 0.40},
    {'name': 'Vanilla', 'price': 0.40},
    {'name': 'Hazelnut', 'price': 0.45},
  ];

  // Get Product object if available
  Product? get _productModel {
    if (widget.product != null && widget.product!['product'] is Product) {
      return widget.product!['product'] as Product;
    }
    return null;
  }

  // Check if product has variants
  bool get _hasVariants {
    return _productModel?.hasVariants == true &&
           _productModel!.variants.isNotEmpty;
  }

  // Get variants list
  List<ProductVariant> get _variants {
    return _productModel?.variants ?? [];
  }

  // Get selected variant (null if no variants)
  ProductVariant? get _selectedVariant {
    if (!_hasVariants) return null;
    if (_selectedVariantIndex >= _variants.length) return _variants.first;
    return _variants[_selectedVariantIndex];
  }

  // Get product data (works with both Product model and Map)
  String get _productName {
    if (_productModel != null) return _productModel!.name;
    return widget.product?['name'] ?? 'Caffe Mocha';
  }

  String get _productDescription {
    if (_productModel != null) return _productModel!.description ?? '';
    return widget.product?['description'] ??
        'A cappuccino is an approximately 150 ml (5 oz) beverage, with 25 ml of espresso coffee and 85ml of fresh milk';
  }

  String get _productType {
    if (_productModel != null) return _productModel!.categoryName ?? 'Ice/Hot';
    return widget.product?['type'] ?? 'Ice/Hot';
  }

  double get _productPrice {
    // If product has variants, use selected variant price
    if (_hasVariants && _selectedVariant != null) {
      return _selectedVariant!.priceAsDouble;
    }
    if (_productModel != null) return _productModel!.priceAsDouble;
    return (widget.product?['price'] ?? 4.53).toDouble();
  }

  double get _productRating {
    return (widget.product?['rating'] ?? 4.8).toDouble();
  }

  int get _productReviews {
    return widget.product?['reviews'] ?? 230;
  }

  String? get _productImage {
    if (_productModel != null) {
      return ApiConfig.getImageUrl(_productModel!.image);
    }
    return widget.product?['image'];
  }

  bool get _isNetworkImage {
    final image = _productImage;
    return image != null && (image.startsWith('http://') || image.startsWith('https://'));
  }

  double get _totalPrice {
    double base = _productPrice;
    double extrasTotal = 0;
    for (int index in _selectedExtras) {
      extrasTotal += _extras[index]['price'];
    }
    return base + extrasTotal;
  }

  void _toggleWishlist() async {
    debugPrint('🔵 [ProductDetail] _toggleWishlist called');
    debugPrint('🔵 [ProductDetail] _productModel: $_productModel');
    debugPrint('🔵 [ProductDetail] widget.product: ${widget.product}');

    if (_productModel == null) {
      debugPrint('🔴 [ProductDetail] _productModel is null! Cannot toggle wishlist.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Product data not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('🔵 [ProductDetail] Product ID: ${_productModel!.id}, Name: ${_productModel!.name}');

    final wishlistProvider = context.read<WishlistProvider>();
    final wasInWishlist = wishlistProvider.isInWishlist(_productModel!.id);

    debugPrint('🔵 [ProductDetail] wasInWishlist: $wasInWishlist');

    await wishlistProvider.toggleWishlist(_productModel!);

    debugPrint('🟢 [ProductDetail] toggleWishlist completed');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasInWishlist ? 'Removed from wishlist' : 'Added to wishlist',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addToCart() async {
    debugPrint('🔵 [ProductDetail] _addToCart called');

    if (_productModel == null) {
      debugPrint('🔴 [ProductDetail] _productModel is null!');
      return;
    }

    // Check if variant is required but not selected
    if (_productModel!.hasVariants && _variants.isEmpty) {
      debugPrint('🔴 [ProductDetail] Product requires variants but none available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product requires a size selection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();

    debugPrint('🔵 [ProductDetail] Adding to cart: ${_productModel!.name}');
    debugPrint('🔵 [ProductDetail] hasVariants: ${_productModel!.hasVariants}');
    debugPrint('🔵 [ProductDetail] selectedVariant: ${_selectedVariant?.name} (id: ${_selectedVariant?.id})');

    final success = await cartProvider.addToCart(
      product: _productModel!,
      variant: _selectedVariant,
    );

    if (success && mounted) {
      setState(() {
        _isAddedToCart = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_productName added to cart!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartProvider.errorMessage ?? 'Failed to add to cart'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch wishlist provider at build level to ensure rebuilds
    final wishlistProvider = context.watch<WishlistProvider>();
    final isInWishlist = _productModel != null
        ? wishlistProvider.isInWishlist(_productModel!.id)
        : false;

    return Scaffold(
      body: PatternBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // App Bar
              _buildAppBar(isInWishlist: isInWishlist),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      _buildProductImage(),

                      // Product Info
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProductInfo(),
                            const SizedBox(height: 24),
                            _buildSizeSelector(),
                            const SizedBox(height: 24),
                            _buildExtrasSection(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar({required bool isInWishlist}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: 12,
      ),
      child: Row(
        children: [
          // Back button
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

          // Title
          Expanded(
            child: Text(
              _productName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
          ),

          // Favorites button
          GestureDetector(
            onTap: _productModel != null ? _toggleWishlist : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isInWishlist ? Icons.favorite : Icons.favorite_border,
                color: isInWishlist ? Colors.red : AppColors.textHeading,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _isNetworkImage
            ? CachedNetworkImage(
                imageUrl: _productImage!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: AppColors.lightGrey,
                  highlightColor: AppColors.white,
                  child: Container(
                    color: AppColors.lightGrey,
                  ),
                ),
                errorWidget: (context, url, error) => _buildImagePlaceholder(),
              )
            : _productImage != null
                ? Image.asset(
                    _productImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: AppColors.grey,
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and Rating row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _productName,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _productType,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Rating
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_productRating',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  ' ($_productReviews)',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Description
        Text(
          _productDescription,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 14,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    // Use actual variants if available, otherwise fallback sizes
    final sizes = _hasVariants
        ? _variants.map((v) => v.name).toList()
        : _fallbackSizes;

    // Don't show size selector if no sizes available
    if (sizes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Size',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(sizes.length, (index) {
            final isSelected = _selectedVariantIndex == index;
            final variant = _hasVariants ? _variants[index] : null;
            final sizeName = sizes[index];

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVariantIndex = index;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < sizes.length - 1 ? 12 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryBackground : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sizeName,
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textHeading,
                        ),
                      ),
                      if (variant != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '£${variant.priceAsDouble.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 12,
                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildExtrasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Extras & Add-ons',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Customize your menu your way',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _extras.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final extra = _extras[index];
              final isSelected = _selectedExtras.contains(index);
              return _buildExtraCard(
                name: extra['name'],
                price: extra['price'],
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedExtras.remove(index);
                    } else {
                      _selectedExtras.add(index);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExtraCard({
    required String name,
    required double price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBackground : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.add,
                color: AppColors.white,
                size: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textHeading,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '£ ${price.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final cartProvider = context.watch<CartProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '£ ${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Buy Now / View Cart button
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isAddedToCart) {
                  Navigator.pushNamed(context, AppRoutes.cart);
                } else {
                  _addToCart();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 56,
                decoration: BoxDecoration(
                  color: _isAddedToCart ? AppColors.textHeading : AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isAddedToCart) ...[
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'View Cart (${cartProvider.itemCount})',
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ] else
                        const Text(
                          'Buy Now',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

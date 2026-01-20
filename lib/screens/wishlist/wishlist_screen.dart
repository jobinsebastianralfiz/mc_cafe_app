import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pattern_background.dart';
import '../../widgets/shimmer_loading.dart';

class WishlistScreen extends StatefulWidget {
  final bool showBottomNav;

  const WishlistScreen({super.key, this.showBottomNav = true});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWishlist();
    });
  }

  Future<void> _loadWishlist() async {
    final wishlistProvider = context.read<WishlistProvider>();
    await wishlistProvider.loadWishlist();
  }

  Future<void> _refreshWishlist() async {
    final wishlistProvider = context.read<WishlistProvider>();
    await wishlistProvider.loadWishlist(forceRefresh: true);
  }

  void _removeFromWishlist(int productId) async {
    final wishlistProvider = context.read<WishlistProvider>();
    final success = await wishlistProvider.removeFromWishlist(productId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Removed from wishlist' : 'Failed to remove from wishlist',
          ),
          backgroundColor: success ? AppColors.primary : AppColors.error,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addToCart(int productId) {
    final wishlistProvider = context.read<WishlistProvider>();
    final cartProvider = context.read<CartProvider>();

    final item = wishlistProvider.items.firstWhere(
      (item) => item.productId == productId,
    );

    if (item.product != null) {
      cartProvider.addToCart(product: item.product!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.productName} added to cart'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = PatternBackground(
      child: SafeArea(
        bottom: !widget.showBottomNav,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );

    if (widget.showBottomNav) {
      return Scaffold(body: content);
    }
    return content;
  }

  Widget _buildContent() {
    final wishlistProvider = context.watch<WishlistProvider>();
    final items = wishlistProvider.items;
    final isLoading = wishlistProvider.status == LoadingStatus.loading;

    if (isLoading && items.isEmpty) {
      return _buildLoadingState();
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshWishlist,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildWishlistItem(item),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    final wishlistProvider = context.watch<WishlistProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: 12,
      ),
      child: Row(
        children: [
          if (widget.showBottomNav)
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
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: Text(
              'Wishlist${wishlistProvider.itemCount > 0 ? ' (${wishlistProvider.itemCount})' : ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: 16,
      ),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ShimmerWidget(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget(
                        child: Container(
                          height: 16,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShimmerWidget(
                        child: Container(
                          height: 14,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShimmerWidget(
                        child: Container(
                          height: 16,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to your wishlist to see them here',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.products);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Browse Products',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(dynamic item) {
    final imageUrl = ApiConfig.getImageUrl(item.productImage);

    return GestureDetector(
      onTap: () {
        if (item.product != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.productDetail,
            arguments: {
              'slug': item.product!.slug,
              'product': item.product,
            },
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.lightGrey,
                        highlightColor: AppColors.white,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
            const SizedBox(width: 12),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeading,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.product?.shortDescription != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.product!.shortDescription!,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '£${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      // Add to cart button
                      GestureDetector(
                        onTap: () => _addToCart(item.productId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_shopping_cart,
                                color: AppColors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Remove from wishlist button
            GestureDetector(
              onTap: () => _removeFromWishlist(item.productId),
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.background,
      child: const Icon(
        Icons.image_outlined,
        size: 32,
        color: AppColors.grey,
      ),
    );
  }
}

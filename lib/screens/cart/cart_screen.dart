import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../data/models/cart_model.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pattern_background.dart';
import '../../widgets/shimmer_loading.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Load cart when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatternBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),

              // Cart Content
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    if (cartProvider.status == LoadingStatus.loading &&
                        cartProvider.items.isEmpty) {
                      return _buildLoadingState();
                    }

                    if (cartProvider.isEmpty) {
                      return _buildEmptyCart();
                    }

                    return RefreshIndicator(
                      onRefresh: () => cartProvider.loadCart(forceRefresh: true),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingL,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),

                              // Cart Items
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: cartProvider.items.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildCartItem(cartProvider.items[index]),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Apply Coupon Code
                              _buildCouponButton(cartProvider),

                              const SizedBox(height: 24),

                              // Order Summary
                              _buildOrderSummary(cartProvider),

                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isEmpty) return const SizedBox.shrink();
          return _buildBottomBar(cartProvider);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShimmerLoading(
              width: double.infinity,
              height: 120,
              borderRadius: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 100,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some items to get started',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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

  Widget _buildAppBar() {
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
          const Expanded(
            child: Text(
              'Cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
          ),

          // Clear cart button
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.isEmpty) {
                return const SizedBox(width: 40);
              }
              return GestureDetector(
                onTap: () => _showClearCartDialog(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CartProvider>().clearCart();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    final cartProvider = context.read<CartProvider>();
    final imageUrl = item.productImage != null
        ? (item.productImage!.startsWith('http')
            ? item.productImage
            : ApiConfig.getImageUrl(item.productImage))
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: AppColors.lightGrey,
                      highlightColor: AppColors.white,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),

          const SizedBox(width: 12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Delete button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
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
                    ),
                    GestureDetector(
                      onTap: () => cartProvider.removeFromCart(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Variant name if available
                if (item.variantName != null)
                  Text(
                    item.variantName!,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),

                // Addons if available
                if (item.hasAddons)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.addons!.map((a) => a.name).join(', '),
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const SizedBox(height: 12),

                // Price and Quantity row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '£${item.itemTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),

                    // Quantity Selector
                    Row(
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (item.quantity > 1) {
                              cartProvider.updateQuantity(item.id, item.quantity - 1);
                            } else {
                              cartProvider.removeFromCart(item.id);
                            }
                          },
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHeading,
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Icons.add,
                          onTap: () {
                            cartProvider.updateQuantity(item.id, item.quantity + 1);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: AppColors.grey,
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.textHeading,
        ),
      ),
    );
  }

  Widget _buildCouponButton(CartProvider cartProvider) {
    final hasCoupon = cartProvider.cart.hasCoupon;

    return GestureDetector(
      onTap: () async {
        if (hasCoupon) {
          // Remove coupon
          cartProvider.removeCoupon();
        } else {
          // Apply coupon
          final result = await Navigator.pushNamed(context, AppRoutes.redeemCoupon);
          if (result != null && result is String && mounted) {
            final success = await cartProvider.applyCoupon(result);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Coupon "$result" applied!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(cartProvider.errorMessage ?? 'Failed to apply coupon'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      child: ClipPath(
        clipper: _TicketClipper(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.textHeading,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasCoupon
                    ? 'Coupon: ${cartProvider.cart.couponCode}'
                    : 'Apply Coupon Code',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              Icon(
                hasCoupon ? Icons.close : Icons.chevron_right,
                color: AppColors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Column(
      children: [
        // Subtotal Row
        _buildSummaryRow('Subtotal', cartProvider.subtotal),

        const SizedBox(height: 12),

        // Tax Row
        _buildSummaryRow('Tax (${cartProvider.cart.summary.taxRate.toStringAsFixed(0)}%)', cartProvider.tax),

        // Discount Row (if any)
        if (cartProvider.discount > 0) ...[
          const SizedBox(height: 12),
          _buildSummaryRow('Discount', -cartProvider.discount, isDiscount: true),
        ],

        const SizedBox(height: 12),

        // Grand Total Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Grand Total',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              '£${cartProvider.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}£${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 16,
            color: isDiscount ? Colors.green : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(CartProvider cartProvider) {
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
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.paymentMethod);
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'Pay Now • £${cartProvider.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom clipper for ticket/coupon shape with semi-circle notches
class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const notchRadius = 10.0;
    const cornerRadius = 12.0;

    // Start from top-left with rounded corner
    path.moveTo(cornerRadius, 0);

    // Top edge
    path.lineTo(size.width - cornerRadius, 0);

    // Top-right rounded corner
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Right edge to notch
    path.lineTo(size.width, size.height / 2 - notchRadius);

    // Right notch (semi-circle cut inward)
    path.arcToPoint(
      Offset(size.width, size.height / 2 + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    // Right edge from notch to bottom
    path.lineTo(size.width, size.height - cornerRadius);

    // Bottom-right rounded corner
    path.quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height);

    // Bottom edge
    path.lineTo(cornerRadius, size.height);

    // Bottom-left rounded corner
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // Left edge from bottom to notch
    path.lineTo(0, size.height / 2 + notchRadius);

    // Left notch (semi-circle cut inward)
    path.arcToPoint(
      Offset(0, size.height / 2 - notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    // Left edge from notch to top
    path.lineTo(0, cornerRadius);

    // Top-left rounded corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

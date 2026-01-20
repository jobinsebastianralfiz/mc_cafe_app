import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pattern_background.dart';
import '../../widgets/shimmer_loading.dart';

// ignore: unused_import needed for OrderTrackingInfo type

class OrderDetailsScreen extends StatefulWidget {
  final int? orderId;
  final Order? order;

  const OrderDetailsScreen({
    super.key,
    this.orderId,
    this.order,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Order? _order;
  OrderTrackingInfo? _trackingInfo;
  bool _isLoading = true;
  bool _isTrackingLoading = true;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final orderProvider = context.read<OrderProvider>();

    // Load order details if we only have ID
    if (_order == null && widget.orderId != null) {
      setState(() => _isLoading = true);
      final order = await orderProvider.loadOrderDetails(widget.orderId!);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }

    // Load tracking info
    final orderId = _order?.id ?? widget.orderId;
    if (orderId != null) {
      setState(() => _isTrackingLoading = true);
      final tracking = await orderProvider.trackOrder(orderId);
      if (mounted) {
        setState(() {
          _trackingInfo = tracking;
          _isTrackingLoading = false;
        });
      }
    } else {
      setState(() => _isTrackingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatternBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _order == null
                        ? _buildErrorState()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingL,
                              vertical: 16,
                            ),
                            child: Column(
                              children: [
                                // Order Info Card
                                _buildOrderInfoCard(),

                                const SizedBox(height: 16),

                                // Order Items
                                _buildOrderItems(),

                                const SizedBox(height: 16),

                                // Order Summary
                                _buildOrderSummary(),

                                const SizedBox(height: 16),

                                // Order Tracking
                                _buildOrderTracking(),

                                const SizedBox(height: 16),

                                // Action Buttons
                                _buildActionButtons(),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
              'Order Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
          ),

          // Empty space for symmetry
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        children: [
          ShimmerLoading(
            width: double.infinity,
            height: 80,
            borderRadius: 16,
          ),
          const SizedBox(height: 16),
          ShimmerLoading(
            width: double.infinity,
            height: 200,
            borderRadius: 16,
          ),
          const SizedBox(height: 16),
          ShimmerLoading(
            width: double.infinity,
            height: 150,
            borderRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Order not found',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              'Go back',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Order ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order ID',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _order?.orderNumber ?? 'N/A',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeading,
                  ),
                ),
              ],
            ),
          ),

          // Token
          if (_order?.formattedToken != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Token',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _order!.formattedToken!,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    final items = _order?.items ?? [];

    return Container(
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
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: index < items.length - 1
                  ? const Border(
                      bottom: BorderSide(color: AppColors.border, width: 1),
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.productImage != null
                      ? CachedNetworkImage(
                          imageUrl: ApiConfig.getImageUrl(item.productImage) ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppColors.lightGrey,
                            highlightColor: AppColors.white,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => _buildItemPlaceholder(),
                        )
                      : _buildItemPlaceholder(),
                ),
                const SizedBox(width: 12),

                // Name and details
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
                      ),
                      const SizedBox(height: 4),
                      if (item.variantName != null)
                        Text(
                          item.variantName!,
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                      Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (item.hasAddons)
                        ...item.addons!.map((addon) => Text(
                              '+ ${addon.name}',
                              style: const TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            )),
                    ],
                  ),
                ),

                // Price
                Text(
                  '£ ${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildItemPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.fastfood_outlined,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal', '£ ${_order!.subtotal.toStringAsFixed(2)}'),
          if (_order!.tax > 0)
            _buildSummaryRow('Tax', '£ ${_order!.tax.toStringAsFixed(2)}'),
          if (_order!.deliveryCharge > 0)
            _buildSummaryRow('Delivery', '£ ${_order!.deliveryCharge.toStringAsFixed(2)}'),
          if (_order!.discount > 0)
            _buildSummaryRow('Discount', '-£ ${_order!.discount.toStringAsFixed(2)}', isDiscount: true),
          const Divider(height: 24),
          _buildSummaryRow('Total', '£ ${_order!.total.toStringAsFixed(2)}', isBold: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _order!.orderType == OrderType.delivery
                    ? Icons.delivery_dining
                    : Icons.store,
                size: 16,
                color: AppColors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _order!.orderType.displayName,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.payment,
                size: 16,
                color: AppColors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _order!.paymentMethod.displayName,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: isBold ? 15 : 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isDiscount ? AppColors.success : (isBold ? AppColors.primary : AppColors.textHeading),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTracking() {
    if (_isTrackingLoading) {
      return ShimmerLoading(
        width: double.infinity,
        height: 200,
        borderRadius: 16,
      );
    }

    if (_trackingInfo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Status',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _trackingInfo!.statusLabel,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(_trackingInfo!.timeline.length, (index) {
            final step = _trackingInfo!.timeline[index];
            final isLast = index == _trackingInfo!.timeline.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline indicator
                Column(
                  children: [
                    // Dot
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.completed
                            ? AppColors.primary
                            : AppColors.grey.withOpacity(0.3),
                      ),
                      child: step.current
                          ? const Center(
                              child: Icon(
                                Icons.check,
                                size: 10,
                                color: AppColors.white,
                              ),
                            )
                          : null,
                    ),
                    // Line
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: step.completed
                            ? AppColors.primary
                            : AppColors.grey.withOpacity(0.3),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Text content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                    child: Text(
                      step.label,
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 14,
                        fontWeight: step.current ? FontWeight.w600 : FontWeight.w400,
                        color: step.completed || step.current
                            ? (step.current ? AppColors.primary : AppColors.textHeading)
                            : AppColors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Reorder button
        if (_order?.canBeReordered ?? false)
          GestureDetector(
            onTap: _handleReorder,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Reorder',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),

        // Cancel button
        if (_order?.canBeCancelled ?? false) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _handleCancel,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error),
              ),
              child: const Center(
                child: Text(
                  'Cancel Order',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleReorder() async {
    if (_order == null) return;

    final orderProvider = context.read<OrderProvider>();
    final result = await orderProvider.reorder(_order!.id);

    if (result != null && mounted) {
      // Refresh cart
      await context.read<CartProvider>().loadCart(forceRefresh: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate to cart
      Navigator.pushNamed(context, AppRoutes.cart);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to reorder'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleCancel() async {
    if (_order == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.cancelOrder(_order!.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to cancel order'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

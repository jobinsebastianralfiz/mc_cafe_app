import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pattern_background.dart';
import '../../widgets/shimmer_loading.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedTabIndex = 0;

  final List<String> _tabs = ['All', 'Upcoming', 'Past'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders(refresh: true);
    });
  }

  List<Order> _getFilteredOrders(List<Order> orders) {
    switch (_selectedTabIndex) {
      case 1: // Upcoming
        return orders.where((order) => order.isActive).toList();
      case 2: // Past
        return orders.where((order) => order.isCompleted || order.isCancelled).toList();
      default: // All
        return orders;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatternBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),

              const SizedBox(height: 16),

              // Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                child: _buildTabBar(),
              ),

              const SizedBox(height: 16),

              // Orders List
              Expanded(
                child: Consumer<OrderProvider>(
                  builder: (context, orderProvider, child) {
                    final filteredOrders = _getFilteredOrders(orderProvider.orders);
                    final isLoading = orderProvider.status == LoadingStatus.loading;

                    if (isLoading && orderProvider.orders.isEmpty) {
                      return _buildLoadingState();
                    }

                    if (filteredOrders.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () => orderProvider.loadOrders(refresh: true),
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingL,
                        ),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildOrderCard(filteredOrders[index]),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
              'Orders',
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

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerLoading(
            width: double.infinity,
            height: 140,
            borderRadius: 16,
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
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your orders will appear here',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    // Get first item for display
    final firstItemName = order.items.isNotEmpty
        ? order.items.first.productName
        : 'Order ${order.orderNumber}';
    final firstItemImage = order.items.isNotEmpty
        ? order.items.first.productImage
        : null;

    // Format date
    final formattedDate = _formatDate(order.createdAt);

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
        children: [
          // Top row - Image, Name, Date, Price, Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: firstItemImage != null
                    ? CachedNetworkImage(
                        imageUrl: ApiConfig.getImageUrl(firstItemImage) ?? '',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: AppColors.lightGrey,
                          highlightColor: AppColors.white,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),

              // Name and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstItemName,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeading,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (order.items.length > 1)
                      Text(
                        '+${order.items.length - 1} more items',
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                  ],
                ),
              ),

              // Price and Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '£ ${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStatusBadge(order.status),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom row - Order ID and Order Details button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Order ID
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 13,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Order ID ',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(
                      text: order.orderNumber,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Order Details button
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.orderDetails,
                    arguments: {
                      'orderId': order.id,
                      'order': order,
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Order Details',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.primary,
        size: 32,
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case OrderStatus.delivered:
      case OrderStatus.completed:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CAF50);
        label = 'Completed';
        break;
      case OrderStatus.preparing:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFF9800);
        label = 'Preparing';
        break;
      case OrderStatus.ready:
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF2196F3);
        label = 'Ready';
        break;
      case OrderStatus.pending:
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFFFC107);
        label = 'Pending';
        break;
      case OrderStatus.confirmed:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CAF50);
        label = 'Confirmed';
        break;
      case OrderStatus.outForDelivery:
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF2196F3);
        label = 'Out for Delivery';
        break;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFF44336);
        label = status == OrderStatus.cancelled ? 'Cancelled' : 'Refunded';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/pattern_background.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic>? order;

  const OrderDetailsScreen({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    final orderData = order ?? {
      'id': '#47547896',
      'estimateTime': '30 minutes',
      'items': [
        {'name': 'Mocha Coffee', 'qty': 2, 'price': 8.99},
        {'name': 'Iced Caramel Latte', 'qty': 1, 'price': 12.50},
      ],
      'trackingStep': 2,
    };

    return Scaffold(
      body: PatternBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingL,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // Order Info Card
                      _buildOrderInfoCard(orderData),

                      const SizedBox(height: 16),

                      // Order Items
                      _buildOrderItems(orderData['items'] as List),

                      const SizedBox(height: 16),

                      // Order Tracking
                      _buildOrderTracking(orderData['trackingStep'] as int),

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
              'Order History',
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

  Widget _buildOrderInfoCard(Map<String, dynamic> orderData) {
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
                  orderData['id'] ?? '#47547896',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeading,
                  ),
                ),
              ],
            ),
          ),

          // Estimate Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Estimate Time',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orderData['estimateTime'] ?? '30 minutes',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(List items) {
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
          final item = items[index] as Map<String, dynamic>;
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
                  child: Image.asset(
                    'assets/images/coffee_cup.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Qty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${item['qty']}',
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
                Text(
                  '£ ${item['price'].toStringAsFixed(2)}',
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

  Widget _buildOrderTracking(int currentStep) {
    final List<Map<String, String>> trackingSteps = [
      {
        'title': 'Order Placed',
        'description': 'We have received your order.',
        'icon': 'assets/icons/order_placed.png',
      },
      {
        'title': 'Order Confirmed',
        'description': 'Your order has been confirmed.',
        'icon': 'assets/icons/order_confirmed.png',
      },
      {
        'title': 'Order Processed',
        'description': 'We are preparing your order.',
        'icon': 'assets/icons/order_processed.png',
      },
      {
        'title': 'Ready to Pickup',
        'description': 'Your order is ready for pickup.',
        'icon': 'assets/icons/order_pickup.png',
      },
    ];

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
        children: List.generate(trackingSteps.length, (index) {
          final step = trackingSteps[index];
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          final isPending = index > currentStep;

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
                      color: isCompleted
                          ? AppColors.primary
                          : isCurrent
                              ? AppColors.primary.withOpacity(0.7)
                              : AppColors.grey.withOpacity(0.3),
                    ),
                  ),
                  // Line
                  if (index < trackingSteps.length - 1)
                    Container(
                      width: 2,
                      height: 50,
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.grey.withOpacity(0.3),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Icon and Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primaryBackground
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Opacity(
                          opacity: isPending ? 0.4 : 1.0,
                          child: Image.asset(
                            step['icon']!,
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title']!,
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isPending
                                    ? AppColors.grey.withOpacity(0.6)
                                    : isCurrent
                                        ? AppColors.primary
                                        : AppColors.textHeading,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step['description']!,
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 13,
                                color: isPending
                                    ? AppColors.grey.withOpacity(0.5)
                                    : isCurrent
                                        ? AppColors.primary.withOpacity(0.8)
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

}

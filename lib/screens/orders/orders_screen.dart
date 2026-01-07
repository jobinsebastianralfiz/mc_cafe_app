import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pattern_background.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedTabIndex = 0;

  final List<String> _tabs = ['All', 'Upcoming', 'Past'];

  final List<Map<String, dynamic>> _allOrders = [
    {
      'id': '#47547896',
      'name': 'Mocha Coffee',
      'date': 'December 18, 2025',
      'price': 8.99,
      'status': 'delivered',
      'image': 'assets/images/coffee_cup.png',
      'items': [
        {'name': 'Mocha Coffee', 'qty': 2, 'price': 8.99},
        {'name': 'Iced Caramel Latte', 'qty': 1, 'price': 12.50},
      ],
      'estimateTime': '30 minutes',
      'trackingStep': 2,
    },
    {
      'id': '#65748232',
      'name': 'Iced Caramel Latte',
      'date': 'November 27, 2025',
      'price': 12.50,
      'status': 'delivered',
      'image': 'assets/images/coffee_cup.png',
      'items': [
        {'name': 'Iced Caramel Latte', 'qty': 1, 'price': 12.50},
      ],
      'estimateTime': '25 minutes',
      'trackingStep': 3,
    },
    {
      'id': '#34120500',
      'name': 'Signature Latte',
      'date': 'November 6, 2025',
      'price': 5.50,
      'status': 'preparing',
      'image': 'assets/images/coffee_cup.png',
      'items': [
        {'name': 'Signature Latte', 'qty': 1, 'price': 5.50},
      ],
      'estimateTime': '15 minutes',
      'trackingStep': 1,
    },
    {
      'id': '#985241106',
      'name': 'Espresso and Donut',
      'date': 'October 15, 2025',
      'price': 6.75,
      'status': 'canceled',
      'image': 'assets/images/coffee_cup.png',
      'items': [
        {'name': 'Espresso', 'qty': 1, 'price': 3.50},
        {'name': 'Donut', 'qty': 1, 'price': 3.25},
      ],
      'estimateTime': '20 minutes',
      'trackingStep': 0,
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    switch (_selectedTabIndex) {
      case 1: // Upcoming
        return _allOrders.where((order) => order['status'] == 'preparing').toList();
      case 2: // Past
        return _allOrders.where((order) =>
          order['status'] == 'delivered' || order['status'] == 'canceled'
        ).toList();
      default: // All
        return _allOrders;
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
                child: _filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingL,
                        ),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildOrderCard(_filteredOrders[index]),
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
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
                child: Image.asset(
                  order['image'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              // Name and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['name'],
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order['date'],
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 13,
                        color: AppColors.textPrimary,
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
                    '£ ${order['price'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStatusBadge(order['status']),
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
                      text: order['id'],
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
                    arguments: order,
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'delivered':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CAF50);
        label = 'Order Delivered';
        break;
      case 'preparing':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFF9800);
        label = 'Preparing';
        break;
      case 'canceled':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFF44336);
        label = 'Canceled';
        break;
      default:
        bgColor = AppColors.grey.withOpacity(0.2);
        textColor = AppColors.textPrimary;
        label = status;
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

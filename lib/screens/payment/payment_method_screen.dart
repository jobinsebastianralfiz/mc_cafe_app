import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pattern_background.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int _selectedPaymentIndex = 0; // Only one option: Pay at Counter
  bool _isLoading = false;
  String _orderType = 'pickup'; // 'pickup' or 'delivery'
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Pay at Counter',
      'icon': 'assets/icons/cash_on_delivery.png',
      'value': 'pay_at_counter',
      'enabled': true,
    },
  ];

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  String _composeAddress() {
    final parts = [
      _addressLine1Controller.text.trim(),
      _addressLine2Controller.text.trim(),
      _cityController.text.trim(),
      _postcodeController.text.trim(),
    ].where((p) => p.isNotEmpty).toList();
    return parts.join(', ');
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

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingL,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Order Type Section
                        _buildSectionTitle('Order Type'),
                        const SizedBox(height: 12),
                        _buildOrderTypeSelector(),
                        const SizedBox(height: 8),

                        // Delivery Address (shown only for delivery)
                        if (_orderType == 'delivery') ...[
                          _buildDeliveryAddressField(),
                          const SizedBox(height: 8),
                        ],

                        const SizedBox(height: 16),

                        // Payment Section
                        _buildSectionTitle('Payment'),
                        const SizedBox(height: 12),
                        _buildPaymentMethods(),

                        const SizedBox(height: 120),
                      ],
                    ),
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
              'Payment Method',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Sora',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textHeading,
      ),
    );
  }

  Widget _buildOrderTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _orderType = 'pickup'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _orderType == 'pickup'
                    ? AppColors.primary
                    : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _orderType == 'pickup'
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 20,
                    color: _orderType == 'pickup'
                        ? AppColors.white
                        : AppColors.textHeading,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pickup',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _orderType == 'pickup'
                          ? AppColors.white
                          : AppColors.textHeading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Opacity(
            opacity: 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delivery_dining_outlined,
                        size: 20,
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Coming soon',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 10,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddressField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAddressField(
            controller: _addressLine1Controller,
            label: 'Address Line 1',
            hint: 'Street address, house/flat no.',
          ),
          const SizedBox(height: 12),
          _buildAddressField(
            controller: _addressLine2Controller,
            label: 'Address Line 2 (Optional)',
            hint: 'Apartment, landmark, etc.',
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildAddressField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'City',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildAddressField(
                  controller: _postcodeController,
                  label: 'Postcode',
                  hint: 'Postcode',
                  capitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextCapitalization capitalization = TextCapitalization.words,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textCapitalization: capitalization,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Sora',
              fontSize: 13,
              color: AppColors.grey.withOpacity(0.6),
            ),
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 14,
            color: AppColors.textHeading,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: List.generate(_paymentMethods.length, (index) {
        final method = _paymentMethods[index];
        final isSelected = _selectedPaymentIndex == index;
        final isEnabled = method['enabled'] as bool? ?? true;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: isEnabled
                ? () {
                    setState(() {
                      _selectedPaymentIndex = index;
                    });
                  }
                : null,
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected && isEnabled
                        ? AppColors.primary
                        : AppColors.border,
                    width: isSelected && isEnabled ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon
                    Image.asset(
                      method['icon'],
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 16),

                    // Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'],
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isEnabled
                                  ? AppColors.textHeading
                                  : AppColors.grey,
                            ),
                          ),
                          if (!isEnabled)
                            const Text(
                              'Coming soon',
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Radio button
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected && isEnabled
                              ? AppColors.primary
                              : AppColors.grey,
                          width: 2,
                        ),
                      ),
                      child: isSelected && isEnabled
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${cartProvider.currencySymbol}${cartProvider.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pay Button
          GestureDetector(
            onTap: _isLoading ? null : _handleCheckout,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: _isLoading ? AppColors.grey : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Text(
                        'Place Order',
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
        ],
      ),
    );
  }

  Future<void> _handleCheckout() async {
    final cartProvider = context.read<CartProvider>();

    // Check if cart is empty
    if (cartProvider.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Get selected payment method
    final paymentMethod =
        _paymentMethods[_selectedPaymentIndex]['value'] as String;

    // Validate delivery address for delivery orders
    final deliveryAddress = _composeAddress();
    if (_orderType == 'delivery') {
      if (_addressLine1Controller.text.trim().isEmpty ||
          _cityController.text.trim().isEmpty ||
          _postcodeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please fill in Address Line 1, City and Postcode'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Pay at counter: proceed directly
    final orderProvider = context.read<OrderProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await orderProvider.checkout(
        orderType: _orderType,
        paymentMethod: paymentMethod,
        deliveryAddress: _orderType == 'delivery' ? deliveryAddress : null,
      );

      if (result != null) {
        // Clear cart after successful checkout
        await cartProvider.loadCart(forceRefresh: true);

        // Trigger order confirmation notification
        if (mounted) {
          final notificationProvider = context.read<NotificationProvider>();
          final itemsSummary = result.order.items.isNotEmpty
              ? result.order.items.first.productName
              : null;
          await notificationProvider.addOrderStatusNotification(
            orderId: result.order.id,
            orderNumber: result.order.orderNumber,
            status: OrderStatus.confirmed,
            itemsSummary: itemsSummary,
          );
        }

        if (mounted) {
          // Navigate to order success screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.orderSuccess,
            (route) => route.settings.name == AppRoutes.home,
            arguments: {
              'orderId': result.order.orderNumber,
              'order': result.order,
              'payment': result.payment,
            },
          );
        }
      } else {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderProvider.errorMessage ?? 'Failed to place order'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

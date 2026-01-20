import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pattern_background.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String? orderId;
  final Order? order;
  final PaymentInfo? payment;

  const OrderSuccessScreen({
    super.key,
    this.orderId,
    this.order,
    this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatternBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              children: [
                const Spacer(flex: 2),
                _buildSuccessIcon(),
                const SizedBox(height: AppConstants.paddingL),
                _buildSuccessTitle(),
                const SizedBox(height: AppConstants.paddingS),
                _buildSuccessMessage(),
                const SizedBox(height: AppConstants.paddingM),
                _buildOrderInfo(),
                if (payment != null) ...[
                  const SizedBox(height: AppConstants.paddingM),
                  _buildPaymentInstructions(),
                ],
                const Spacer(flex: 2),
                _buildOrderDetailsButton(context),
                const SizedBox(height: AppConstants.paddingM),
                _buildBackToHomeButton(context),
                const SizedBox(height: AppConstants.paddingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Image.asset(
      'assets/images/order_success_icon.png',
      width: 120,
      height: 120,
    );
  }

  Widget _buildSuccessTitle() {
    return Text(
      'Order Successful!',
      style: AppTextStyles.heading1.copyWith(
        fontSize: 26,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSuccessMessage() {
    return Text(
      'Your order has been placed successfully!',
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOrderInfo() {
    final displayOrderId = order?.orderNumber ?? orderId ?? 'N/A';
    final token = order?.formattedToken;

    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            children: [
              const TextSpan(text: 'Order ID '),
              TextSpan(
                text: displayOrderId,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (token != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Your Token',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  token,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentInstructions() {
    if (payment == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            payment!.required ? Icons.payment : Icons.store,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              payment!.instructions,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsButton(BuildContext context) {
    return CustomButton(
      text: 'Order Details',
      onPressed: () {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.orderDetails,
          arguments: {
            'orderId': order?.id,
            'order': order,
          },
        );
      },
    );
  }

  Widget _buildBackToHomeButton(BuildContext context) {
    return CustomButton(
      text: 'Back to Home',
      type: ButtonType.text,
      onPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pattern_background.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    final success = await authProvider.resendOtp(email: email);

    if (!mounted) return;

    if (success) {
      _showSnackBar('OTP sent to your email');
      Navigator.pushNamed(
        context,
        AppRoutes.otpVerification,
        arguments: {'email': email},
      );
    } else {
      _showSnackBar(
        authProvider.errorMessage ?? 'Failed to send OTP',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: PatternBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingL,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.12),

                  // Verification Icon
                  const _VerificationIcon(),

                  SizedBox(height: screenHeight * 0.04),

                  // Heading
                  Text(
                    'OTP Verification',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 36 / 28,
                      color: AppColors.textHeading,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'We will send you an once time password via this email address',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.accent,
                        height: 1.4,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // Email field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Enter email address',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.grey,
                      size: 20,
                    ),
                    validator: Validators.validateEmail,
                    onSubmitted: (_) => _handleSendOtp(),
                  ),

                  const SizedBox(height: 20),

                  // Send OTP button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return CustomButton(
                        text: 'Send OTP',
                        onPressed: _handleSendOtp,
                        isLoading: auth.isLoading,
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationIcon extends StatelessWidget {
  const _VerificationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
            AppColors.accent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        color: AppColors.white,
        size: 50,
      ),
    );
  }
}
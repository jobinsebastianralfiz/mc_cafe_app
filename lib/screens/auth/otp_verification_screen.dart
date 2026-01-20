import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pattern_background.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? email;

  const OtpVerificationScreen({super.key, this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isResending = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == 4;

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _handleVerify() async {
    if (!_isOtpComplete) {
      _showSnackBar('Please enter the complete OTP', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final email = widget.email ?? authProvider.user?.email ?? '';

    if (email.isEmpty) {
      _showSnackBar('Email not found. Please try again.', isError: true);
      return;
    }

    final success = await authProvider.verifyOtp(
      email: email,
      otp: _otpCode,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to home and clear all previous routes
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } else {
      _showSnackBar(
        authProvider.errorMessage ?? 'Invalid OTP. Please try again.',
        isError: true,
      );
      // Clear OTP fields on error
      _clearOtpFields();
    }
  }

  Future<void> _handleResendCode() async {
    final authProvider = context.read<AuthProvider>();
    final email = widget.email ?? authProvider.user?.email ?? '';

    if (email.isEmpty) {
      _showSnackBar('Email not found. Please try again.', isError: true);
      return;
    }

    setState(() => _isResending = true);

    final success = await authProvider.resendOtp(email: email);

    if (!mounted) return;

    setState(() => _isResending = false);

    if (success) {
      _showSnackBar('OTP has been resent to your email');
      _clearOtpFields();
    } else {
      _showSnackBar(
        authProvider.errorMessage ?? 'Failed to resend OTP',
        isError: true,
      );
    }
  }

  void _clearOtpFields() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
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
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.12),

                // Verification Icon
                const _VerificationIcon(),

                SizedBox(height: screenHeight * 0.04),

                // Heading
                Text(
                  'Enter your\nverification code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 36 / 28,
                    color: AppColors.textHeading,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle with email
                Text(
                  widget.email != null
                      ? 'We sent a code to ${widget.email}'
                      : 'Enter your otp code number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.accent,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),

                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: EdgeInsets.only(
                        right: index < 3 ? 16 : 0,
                      ),
                      child: _OtpInputBox(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (value) => _onOtpDigitChanged(index, value),
                      ),
                    );
                  }),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Verify button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return CustomButton(
                      text: 'Verify',
                      onPressed: _handleVerify,
                      isLoading: auth.isLoading,
                    );
                  },
                ),

                SizedBox(height: screenHeight * 0.03),

                // Didn't receive code text
                Text(
                  "Didn't you receive any code?",
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                // Resend code link
                GestureDetector(
                  onTap: _isResending ? null : _handleResendCode,
                  child: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Text(
                          'Resend New Code',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                ),

                SizedBox(height: screenHeight * 0.04),
              ],
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

class _OtpInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpInputBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        onChanged: onChanged,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          fontFamily: 'Sora',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

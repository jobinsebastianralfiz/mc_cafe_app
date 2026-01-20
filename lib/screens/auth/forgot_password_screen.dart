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
import '../../widgets/social_login_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar('Password reset link sent to your email');
      // Navigate back to login after success
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      _showSnackBar(
        authProvider.errorMessage ?? 'Failed to send reset link',
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

  void _handleGoogleLogin() {
    // TODO: Implement Google login
  }

  void _handleAppleLogin() {
    // TODO: Implement Apple login
  }

  void _handleLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
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
                  SizedBox(height: screenHeight * 0.08),

                  // Illustration with contrast and highlights effect
                  ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      1.2, 0, 0, 0, 10,
                      0, 1.2, 0, 0, 10,
                      0, 0, 1.2, 0, 10,
                      0, 0, 0, 1, 0,
                    ]),
                    child: Image.asset(
                      'assets/images/forgot_password_illustration.png',
                      width: 221,
                      height: 221,
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Heading
                  Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 36 / 28,
                      color: AppColors.textHeading,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    "Don't worry happens to the best of us.\nType your email to reset your password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.accent,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Email field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email or Mobile',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.grey,
                      size: 20,
                    ),
                    validator: Validators.validateEmail,
                    onSubmitted: (_) => _handleSend(),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Send button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return CustomButton(
                        text: 'Send',
                        onPressed: _handleSend,
                        isLoading: auth.isLoading,
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remember your Password? ',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleLogin,
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Or continue with
                  Text(
                    'Or continue with',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Social login buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SocialLoginButton(
                        type: SocialLoginType.google,
                        onPressed: _handleGoogleLogin,
                      ),
                      const SizedBox(width: 20),
                      SocialLoginButton(
                        type: SocialLoginType.apple,
                        onPressed: _handleAppleLogin,
                      ),
                    ],
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

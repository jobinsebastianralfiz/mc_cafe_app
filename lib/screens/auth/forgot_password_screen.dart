import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      // TODO: Implement forgot password logic
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    }
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
                  CustomButton(
                    text: 'Send',
                    onPressed: _handleSend,
                    isLoading: _isLoading,
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

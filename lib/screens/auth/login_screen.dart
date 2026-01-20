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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
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
      // Show error message
      _showErrorSnackBar(authProvider.errorMessage ?? 'Login failed');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
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

  void _handleForgotPassword() {
    Navigator.pushNamed(context, AppRoutes.forgotPassword);
  }

  void _handleRegister() {
    Navigator.pushReplacementNamed(context, AppRoutes.register);
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
                  SizedBox(height: screenHeight * 0.06),

                  // Logo
                  Image.asset(
                    'assets/logos/mc_logo.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Heading
                  Text(
                    'Hello Again!',
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
                  Text(
                    "Welcome back you've\nbeen missed!",
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
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.grey,
                      size: 20,
                    ),
                    validator: Validators.validateEmail,
                  ),

                  const SizedBox(height: 16),

                  // Password field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.grey,
                      size: 20,
                    ),
                    validator: Validators.validatePassword,
                    onSubmitted: (_) => _handleLogin(),
                  ),

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Recovery password',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Sign In button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return CustomButton(
                        text: 'Sign In',
                        onPressed: _handleLogin,
                        isLoading: auth.isLoading,
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Not a member? ',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleRegister,
                        child: Text(
                          'Register Now',
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

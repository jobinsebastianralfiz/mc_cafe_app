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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to OTP verification
      Navigator.pushNamed(
        context,
        AppRoutes.otpVerification,
        arguments: {'email': _emailController.text.trim()},
      );
    } else {
      // Show error message
      _showErrorSnackBar(authProvider.errorMessage ?? 'Registration failed');
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
                    'Welcome!',
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
                    'We are very excited to have\nyou join the family',
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

                  // Name field
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Full Name',
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppColors.grey,
                      size: 20,
                    ),
                    validator: Validators.validateName,
                  ),

                  const SizedBox(height: 16),

                  // Email field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
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
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.grey,
                      size: 20,
                    ),
                    validator: Validators.validatePassword,
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.grey,
                      size: 20,
                    ),
                    validator: (value) => Validators.validateConfirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    onSubmitted: (_) => _handleRegister(),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Sign Up button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return CustomButton(
                        text: 'Sign Up',
                        onPressed: _handleRegister,
                        isLoading: auth.isLoading,
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Do you have an Account? ',
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

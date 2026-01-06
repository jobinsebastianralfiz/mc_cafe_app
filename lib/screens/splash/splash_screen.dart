import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pattern_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // TODO: Add animation controllers if needed

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: PatternBackground(
        backgroundImage: Image.asset(
          'assets/images/coffee_cup.png',
          fit: BoxFit.cover,
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.08),

              // Logo
              Image.asset(
                'assets/logos/mc_logo.png',
                height: 80,
                fit: BoxFit.contain,
              ),

              const Spacer(),

              // Bottom content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingL,
                ),
                child: Column(
                  children: [
                    // Heading
                    Text(
                      'A Taste Worth\nSavouring',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 36 / 28,
                        color: AppColors.accent,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Blended Daily By Our Dedicated Team',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accent,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Get Started button
                    CustomButton(
                      text: 'Get Started',
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      },
                    ),

                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

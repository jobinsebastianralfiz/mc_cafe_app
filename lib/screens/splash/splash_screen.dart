import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pattern_background.dart';

/// Splash / bootstrap screen.
///
/// Restores auth state, then routes:
///  - authenticated user  → home
///  - everyone else        → home in guest mode (public menu). Account actions
///    prompt for login via [AuthGuard]; there is no login wall on launch.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Defer initialization to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();

    // Initialize auth state (silently validates any stored token).
    await authProvider.init();

    if (!mounted) return;

    // If user is already logged in, go directly to home.
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }

    // Not logged in → open the public menu as a guest. Account actions
    // (cart, checkout, orders, profile) prompt for login via AuthGuard.
    authProvider.continueAsGuest();
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatternBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logos/mc_logo.png',
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

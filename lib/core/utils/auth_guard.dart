import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

/// Helper for gating account-based actions behind authentication.
///
/// Guests (users who chose "Browse as Guest") can browse the menu, categories,
/// banners and product details freely. Anything tied to an account — Add to
/// Cart, Checkout, Wishlist, Orders, Profile, Notifications — must call
/// [requireAuth] first. When the user is a guest it shows a login prompt and
/// returns `false`, so the caller should abort the action.
class AuthGuard {
  AuthGuard._();

  /// Returns `true` if the user is authenticated and the action may proceed.
  /// Otherwise shows a login prompt and returns `false`.
  ///
  /// [action] is woven into the prompt copy, e.g. "add items to your cart".
  static bool requireAuth(
    BuildContext context, {
    String action = 'use this feature',
  }) {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) return true;
    showLoginPrompt(context, action: action);
    return false;
  }

  /// Shows the "Login required" bottom sheet.
  static Future<void> showLoginPrompt(
    BuildContext context, {
    String action = 'use this feature',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _LoginPromptSheet(action: action),
    );
  }
}

class _LoginPromptSheet extends StatelessWidget {
  final String action;

  const _LoginPromptSheet({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Login Required',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in or create an account to $action.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 28),

          // Log In
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Log In',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Create Account
          SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.register);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Keep browsing
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Keep Browsing',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

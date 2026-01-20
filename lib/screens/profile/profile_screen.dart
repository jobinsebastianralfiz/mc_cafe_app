import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pattern_background.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBottomNav;

  const ProfileScreen({super.key, this.showBottomNav = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadUserData();
      _isInitialized = true;
    }
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _mobileController.text = user.phone ?? '';
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _mobileController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to update profile'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Sora',
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requested'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Sora',
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = PatternBackground(
      child: SafeArea(
        bottom: !widget.showBottomNav,
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingL,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Profile Card
                      _buildProfileCard(),

                      const SizedBox(height: 24),

                      // Delete Account
                      GestureDetector(
                        onTap: _showDeleteAccountDialog,
                        child: const Text(
                          'Delete Account',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.showBottomNav) {
      return Scaffold(body: content);
    }
    return content;
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: 12,
      ),
      child: Row(
        children: [
          // Back button (only show when standalone)
          if (widget.showBottomNav)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textHeading,
                  size: 18,
                ),
              ),
            )
          else
            const SizedBox(width: 40),

          // Title
          const Expanded(
            child: Text(
              'My Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
          ),

          // Empty space for symmetry
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.name.split(' ').first ?? 'Guest';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Photo
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: ClipOval(
                  child: user?.avatar != null
                      ? Image.network(
                          user!.avatar!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar(firstName);
                          },
                        )
                      : _buildDefaultAvatar(firstName),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // Handle photo change
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Change photo'),
                        backgroundColor: AppColors.primary,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Full Name
          _buildLabeledField('Full Name', _nameController),

          const SizedBox(height: 16),

          // Mobile
          _buildLabeledField('Mobile', _mobileController, keyboardType: TextInputType.phone),

          const SizedBox(height: 16),

          // Email
          _buildLabeledField('Email', _emailController, keyboardType: TextInputType.emailAddress),

          const SizedBox(height: 24),

          // Update Profile Button
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return GestureDetector(
                onTap: auth.isLoading ? null : _updateProfile,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: auth.isLoading
                        ? AppColors.primary.withValues(alpha: 0.7)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Update Profile',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 100,
      height: 100,
      color: AppColors.primary,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'G',
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: controller,
          hintText: label,
          keyboardType: keyboardType,
        ),
      ],
    );
  }
}

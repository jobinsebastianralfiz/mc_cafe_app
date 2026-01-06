import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTap;
  final VoidCallback onClose;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight,
                  Color(0xFFFFFCF9),
                ],
                stops: [0.0, 0.3, 1.0],
              ),
            ),
          ),

          // Pattern overlay
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.15),
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/images/background_pattern.png',
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),

          // Content
          Column(
            children: [
              // Header with user info
              _buildHeader(),

              // Menu items
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      _DrawerItem(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: selectedIndex == 0,
                        onTap: () => onItemTap(0),
                      ),
                      _DrawerItem(
                        icon: Icons.grid_view_outlined,
                        selectedIcon: Icons.grid_view_rounded,
                        label: 'Products',
                        isSelected: selectedIndex == 1,
                        onTap: () => onItemTap(1),
                      ),
                      _DrawerItem(
                        icon: Icons.shopping_bag_outlined,
                        selectedIcon: Icons.shopping_bag_rounded,
                        label: 'Orders',
                        isSelected: selectedIndex == 2,
                        onTap: () => onItemTap(2),
                      ),
                      _DrawerItem(
                        icon: Icons.notifications_outlined,
                        selectedIcon: Icons.notifications_rounded,
                        label: 'Notifications',
                        isSelected: selectedIndex == 3,
                        onTap: () => onItemTap(3),
                      ),
                      _DrawerItem(
                        icon: Icons.favorite_border_rounded,
                        selectedIcon: Icons.favorite_rounded,
                        label: 'Wishlist',
                        isSelected: selectedIndex == 4,
                        onTap: () => onItemTap(4),
                      ),
                      _DrawerItem(
                        icon: Icons.person_outline_rounded,
                        selectedIcon: Icons.person_rounded,
                        label: 'Profile',
                        isSelected: selectedIndex == 5,
                        onTap: () => onItemTap(5),
                      ),
                      _DrawerItemWithImage(
                        imagePath: 'assets/icons/logout.png',
                        label: 'Logout',
                        onTap: () => onItemTap(-1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
              color: AppColors.white,
            ),
            child: const ClipOval(
              child: Icon(
                Icons.person,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Name
          const Text(
            'Rishan Pathari',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            'rishanang@gmail.com',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 14,
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 24,
                  color: isSelected ? AppColors.primary : AppColors.textHeading,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : AppColors.textHeading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItemWithImage extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _DrawerItemWithImage({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Image.asset(
                  imagePath,
                  width: 24,
                  height: 24,
                  color: AppColors.textHeading,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textHeading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

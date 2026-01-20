import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int cartCount;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            outlinedIcon: Icons.home_outlined,
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.favorite_rounded,
            outlinedIcon: Icons.favorite_border_rounded,
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.shopping_bag_rounded,
            outlinedIcon: Icons.shopping_bag_outlined,
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
            badgeCount: cartCount,
          ),
          _NavItem(
            icon: Icons.person_rounded,
            outlinedIcon: Icons.person_outline_rounded,
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? icon : outlinedIcon,
                  size: 26,
                  color: isSelected ? AppColors.primary : AppColors.grey,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 24 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

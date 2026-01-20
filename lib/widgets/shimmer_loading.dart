import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme/app_colors.dart';

/// Generic shimmer widget that wraps a child with shimmer effect
class ShimmerWidget extends StatelessWidget {
  final Widget child;

  const ShimmerWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey,
      highlightColor: AppColors.white,
      child: child,
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey,
      highlightColor: AppColors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey,
      highlightColor: AppColors.white,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerCategoryIcon extends StatelessWidget {
  const ShimmerCategoryIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey,
      highlightColor: AppColors.white,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 50,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerBanner extends StatelessWidget {
  const ShimmerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey,
      highlightColor: AppColors.white,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class ShimmerChip extends StatelessWidget {
  const ShimmerChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey,
      highlightColor: AppColors.white,
      child: Container(
        width: 80,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

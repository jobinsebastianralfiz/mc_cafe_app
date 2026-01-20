import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme/app_colors.dart';

/// A reusable cached network image widget with shimmer loading effect.
///
/// Features:
/// - Caches images for faster subsequent loads
/// - Shows shimmer effect while loading
/// - Shows placeholder on error
/// - Supports custom border radius and fit
class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildShimmer(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      ),
    );
  }

  Widget _buildShimmer() {
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

  Widget _buildErrorWidget() {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.grey,
        size: 24,
      ),
    );
  }
}

/// Cached image specifically designed for product images
class ProductCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;

  const ProductCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return AppCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      borderRadius: borderRadius,
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(
          Icons.fastfood_outlined,
          color: AppColors.primary,
          size: 32,
        ),
      ),
    );
  }
}

/// Cached image specifically designed for category icons
class CategoryCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;

  const CategoryCachedImage({
    super.key,
    required this.imageUrl,
    this.size = 64,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return AppCachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: borderRadius,
      errorWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(
          Icons.category_outlined,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }
}

/// Cached image specifically designed for banner images
class BannerCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double height;
  final double borderRadius;

  const BannerCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height = 140,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return AppCachedImage(
      imageUrl: imageUrl,
      width: width ?? double.infinity,
      height: height,
      borderRadius: borderRadius,
      errorWidget: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(
          Icons.image_outlined,
          color: AppColors.primary,
          size: 48,
        ),
      ),
    );
  }
}

/// Cached image for user avatars
class AvatarCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? fallbackText;

  const AvatarCachedImage({
    super.key,
    required this.imageUrl,
    this.size = 48,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback();
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildShimmer(),
        errorWidget: (context, url, error) => _buildFallback(),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey,
      highlightColor: AppColors.white,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.lightGrey,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primaryBackground,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: fallbackText != null
            ? Text(
                fallbackText!.isNotEmpty ? fallbackText![0].toUpperCase() : '?',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                Icons.person,
                color: AppColors.primary,
                size: size * 0.5,
              ),
      ),
    );
  }
}

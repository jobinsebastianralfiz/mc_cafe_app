import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme/app_colors.dart';

class CategoryIcon extends StatelessWidget {
  final String? iconPath;
  final String? imageUrl;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryIcon({
    super.key,
    this.iconPath,
    this.imageUrl,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  bool get _isNetworkImage =>
      imageUrl != null &&
      (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _buildImage(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textHeading,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (_isNetworkImage) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildShimmer(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else if (iconPath != null) {
      return Image.asset(
        iconPath!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey,
      highlightColor: AppColors.white,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.lightGrey,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryBackground,
      child: Center(
        child: Icon(
          Icons.category_outlined,
          size: 32,
          color: isSelected ? AppColors.primary : AppColors.grey,
        ),
      ),
    );
  }
}

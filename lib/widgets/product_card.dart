import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme/app_colors.dart';

class ProductCard extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final String name;
  final String? description;
  final double rating;
  final double? price;
  final String currencySymbol;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onFavoriteTap;

  const ProductCard({
    super.key,
    this.imagePath,
    this.imageUrl,
    required this.name,
    this.description,
    required this.rating,
    this.price,
    this.currencySymbol = '£',
    this.isFavorite = false,
    this.onTap,
    this.onAddTap,
    this.onFavoriteTap,
  });

  bool get _isNetworkImage =>
      imageUrl != null &&
      (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with rating and favorite
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _buildImage(),
                ),
                // Favorite button
                if (onFavoriteTap != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : AppColors.grey,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                // Rating badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeading,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (price != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$currencySymbol ${price!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        GestureDetector(
                          onTap: onAddTap,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_isNetworkImage) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildShimmer(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else if (imagePath != null) {
      return Image.asset(
        imagePath!,
        height: 120,
        width: double.infinity,
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
        height: 120,
        width: double.infinity,
        color: AppColors.lightGrey,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: AppColors.primaryBackground,
      child: const Icon(
        Icons.fastfood_outlined,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }
}

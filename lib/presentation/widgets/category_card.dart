import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/category_model.dart';
import '../products/products_list_screen.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const CategoryCard({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductsListScreen(categoryName: category.name),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Thumbnail
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.lightCream,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImage(),
            ),
            const SizedBox(width: 14),

            // Category Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.displayName.isNotEmpty ? category.displayName : category.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (category.description != null && category.description!.isNotEmpty)
                        ? category.description!
                        : 'Pure farm fresh ${category.name.toLowerCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (category.image != null && category.image!.isNotEmpty) {
      String img = category.image!;
      if (!img.startsWith('http')) {
        final serverRoot = ApiEndpoints.baseUrl.replaceAll('/api', '');
        img = '$serverRoot${img.startsWith('/') ? img : '/$img'}';
      }
      return CachedNetworkImage(
        imageUrl: img,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    String asset = 'assets/images/products/fresh_cow_milk.jpg';
    final nameLower = category.name.toLowerCase();
    if (nameLower.contains('ghee')) {
      asset = 'assets/images/products/pure_cow_ghee.jpg';
    } else if (nameLower.contains('paneer')) {
      asset = 'assets/images/products/fresh_paneer.jpg';
    } else if (nameLower.contains('oil') || nameLower.contains('masala') || nameLower.contains('curd')) {
      asset = 'assets/images/products/product_lineup.jpg';
    }

    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Text(category.emoji ?? '🥛', style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}


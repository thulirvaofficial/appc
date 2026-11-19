import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../products/products_list_screen.dart';

class HomeCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onTap;

  const HomeCategoryCard({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = category.displayName.isNotEmpty ? category.displayName : category.name;

    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductsListScreen(categoryName: category.name),
              ),
            );
          },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EDE2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Image (68px height) using Mobile App Image exclusively
            SizedBox(
              height: 68,
              width: double.infinity,
              child: (!category.hasCustomImage || category.mobileImageUrl.isEmpty)
                  ? Container(
                      color: const Color(0xFFF0F6EE),
                      child: Center(
                        child: Text(category.emoji ?? '🥛', style: const TextStyle(fontSize: 28)),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: category.mobileImageUrl,
                      cacheKey: '${category.id}_${category.updatedAt ?? category.mobileImageUrl}',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFFF3F7F2),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFF0F6EE),
                        child: Center(
                          child: Text(category.emoji ?? '🥛', style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
            ),
            // Bottom Category Label
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Center(
                  child: Text(
                    displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestGreen,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


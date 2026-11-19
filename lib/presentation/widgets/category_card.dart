import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../products/products_list_screen.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = category.displayName.isNotEmpty ? category.displayName : category.name;
    final hasDescription = category.description != null && category.description!.trim().isNotEmpty;
    final description = hasDescription ? category.description!.trim() : null;

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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EFE5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Thumbnail (Left, 96px width)
              SizedBox(
                width: 96,
                child: _buildPhoto(),
              ),

              // Title & Optional Dynamic Description (Center)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Category Title Row with Icon/Emoji
                      Row(
                        children: [
                          if (category.categoryIcon != null && category.categoryIcon!.isNotEmpty) ...[
                            Text(
                              category.categoryIcon!,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(width: 6),
                          ] else ...[
                            const Icon(
                              Icons.eco_outlined,
                              size: 16,
                              color: AppColors.forestGreen,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                color: AppColors.forestGreen,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Dynamic Description: ONLY rendered when non-null and non-empty from backend.
                      // Never displays default/marketing text when absent, adjusting layout naturally.
                      if (hasDescription && description != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Color(0xFF637868),
                            fontSize: 12,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Circular Arrow Button (Right)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCEFD7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: AppColors.forestGreen,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    return CachedNetworkImage(
      imageUrl: category.mobileImageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: const Color(0xFFF3F7F2),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => _fallbackPhoto(),
    );
  }

  Widget _fallbackPhoto() {
    return Container(
      color: const Color(0xFFF0F6EE),
      child: Center(
        child: Text(
          category.categoryIcon ?? category.emoji ?? '🌿',
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

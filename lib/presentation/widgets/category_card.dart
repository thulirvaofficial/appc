import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_endpoints.dart';
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

  // Map category names to reference assets, icons, and descriptions
  static final Map<String, _CatMeta> _metaMap = {
    'milk': _CatMeta(
      asset: 'assets/images/cat_fresh_milk.png',
      icon: Icons.local_drink_outlined,
      defaultDesc: 'Farm fresh A2 raw & chilled cow milk from our farms',
    ),
    'cow milk': _CatMeta(
      asset: 'assets/images/cat_fresh_milk.png',
      icon: Icons.local_drink_outlined,
      defaultDesc: 'Farm fresh A2 raw & chilled cow milk from our farms',
    ),
    'fresh cow milk': _CatMeta(
      asset: 'assets/images/cat_fresh_milk.png',
      icon: Icons.local_drink_outlined,
      defaultDesc: 'Farm fresh A2 raw & chilled cow milk from our farms',
    ),
    'ghee': _CatMeta(
      asset: 'assets/images/cat_ghee_butter.png',
      icon: Icons.soup_kitchen_outlined,
      defaultDesc: 'Traditional hand-churned Bilona ghee and fresh butter',
    ),
    'ghee & butter': _CatMeta(
      asset: 'assets/images/cat_ghee_butter.png',
      icon: Icons.soup_kitchen_outlined,
      defaultDesc: 'Traditional hand-churned Bilona ghee and fresh butter',
    ),
    'paneer': _CatMeta(
      asset: 'assets/images/cat_paneer_tofu.png',
      icon: Icons.bakery_dining_outlined,
      defaultDesc: 'Soft, melt-in-mouth cottage cheese and protein-rich tofu',
    ),
    'paneer & tofu': _CatMeta(
      asset: 'assets/images/cat_paneer_tofu.png',
      icon: Icons.bakery_dining_outlined,
      defaultDesc: 'Soft, melt-in-mouth cottage cheese and protein-rich tofu',
    ),
    'curd': _CatMeta(
      asset: 'assets/images/cat_set_curd.png',
      icon: Icons.rice_bowl_outlined,
      defaultDesc: 'Naturally cultured probiotic thick curd for a healthy gut',
    ),
    'natural set curd': _CatMeta(
      asset: 'assets/images/cat_set_curd.png',
      icon: Icons.rice_bowl_outlined,
      defaultDesc: 'Naturally cultured probiotic thick curd for a healthy gut',
    ),
    'oils': _CatMeta(
      asset: 'assets/images/cat_cold_pressed_oils.png',
      icon: Icons.water_drop_outlined,
      defaultDesc: 'Traditional wooden chekku cold-pressed oils, unrefined & pure',
    ),
    'cold-pressed oils': _CatMeta(
      asset: 'assets/images/cat_cold_pressed_oils.png',
      icon: Icons.water_drop_outlined,
      defaultDesc: 'Traditional wooden chekku cold-pressed oils, unrefined & pure',
    ),
    'spices': _CatMeta(
      asset: 'assets/images/cat_spices_masalas.png',
      icon: Icons.science_outlined,
      defaultDesc: 'Single-origin Salem turmeric, spices and authentic masalas',
    ),
    'pure spices & masalas': _CatMeta(
      asset: 'assets/images/cat_spices_masalas.png',
      icon: Icons.science_outlined,
      defaultDesc: 'Single-origin Salem turmeric, spices and authentic masalas',
    ),
    'vegan': _CatMeta(
      asset: 'assets/images/cat_vegan_plant.png',
      icon: Icons.eco_outlined,
      defaultDesc: 'Nutritious dairy-free and plant-based alternatives',
    ),
    'vegan & plant-based': _CatMeta(
      asset: 'assets/images/cat_vegan_plant.png',
      icon: Icons.eco_outlined,
      defaultDesc: 'Nutritious dairy-free and plant-based alternatives',
    ),
  };

  _CatMeta? _findMeta() {
    final lowerName = category.name.trim().toLowerCase();
    for (final entry in _metaMap.entries) {
      if (lowerName.contains(entry.key) || entry.key.contains(lowerName)) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final meta = _findMeta();
    final displayName = category.displayName.isNotEmpty ? category.displayName : category.name;
    final description = (category.description != null && category.description!.isNotEmpty)
        ? category.description!
        : (meta?.defaultDesc ?? 'Pure farm fresh ${category.name.toLowerCase()} products');

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
              // Photo Thumbnail (Left)
              SizedBox(
                width: 96,
                height: 82,
                child: _buildPhoto(meta),
              ),

              // Title & Description (Center)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            meta?.icon ?? Icons.eco_outlined,
                            size: 16,
                            color: AppColors.forestGreen,
                          ),
                          const SizedBox(width: 6),
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
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFF637868),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildPhoto(_CatMeta? meta) {
    if (category.image != null && category.image!.isNotEmpty) {
      final imgUrl = ApiEndpoints.resolveImageUrl(category.image!);
      return CachedNetworkImage(
        imageUrl: imgUrl,
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
        errorWidget: (_, __, ___) => (meta?.asset != null)
            ? Image.asset(
                meta!.asset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackPhoto(),
              )
            : _fallbackPhoto(),
      );
    }
    if (meta?.asset != null) {
      return Image.asset(
        meta!.asset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackPhoto(),
      );
    }
    return _fallbackPhoto();
  }

  Widget _fallbackPhoto() {
    return Container(
      color: const Color(0xFFF0F6EE),
      child: const Center(
        child: Icon(Icons.eco, color: AppColors.forestGreen, size: 28),
      ),
    );
  }
}

class _CatMeta {
  final String asset;
  final IconData icon;
  final String defaultDesc;

  const _CatMeta({
    required this.asset,
    required this.icon,
    required this.defaultDesc,
  });
}

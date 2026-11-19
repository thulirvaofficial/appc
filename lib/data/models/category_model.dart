import '../../core/constants/api_endpoints.dart';

class CategoryModel {
  final dynamic id;
  final dynamic categoryId;
  final String categoryKey;
  final String name;
  final String categoryName;
  final String displayName;
  final String? description;
  final String? categoryDescription;
  final String? categoryImage;
  final String? mobileImage;
  final String? websiteImage;
  final String? image;
  final String? emoji;
  final String? categoryIcon;
  final bool isActive;
  final int displayOrder;
  final int itemCount;
  final String? updatedAt;

  CategoryModel({
    required this.id,
    dynamic categoryId,
    String? categoryKey,
    required this.name,
    String? categoryName,
    required this.displayName,
    this.description,
    this.categoryDescription,
    this.categoryImage,
    this.mobileImage,
    this.websiteImage,
    this.image,
    this.emoji,
    this.categoryIcon,
    this.isActive = true,
    this.displayOrder = 1,
    this.itemCount = 0,
    this.updatedAt,
  })  : categoryId = categoryId ?? id,
        categoryKey = categoryKey ?? name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
        categoryName = categoryName ?? name;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final catId = json['category_id'] ?? json['id'] ?? 0;
    final catName = (json['category_name'] ?? json['name'] ?? json['displayName'] ?? json['display_name'] ?? '').toString();
    final dispName = (json['displayName'] ?? json['display_name'] ?? json['category_name'] ?? json['name'] ?? '').toString();
    final catKey = (json['category_key'] ?? json['slug'] ?? catName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')).toString();

    // Dynamic Description: Only set if non-empty string in backend. Never use fallback default text.
    final rawDesc = json['category_description'] ?? json['description'];
    final desc = (rawDesc != null && rawDesc.toString().trim().isNotEmpty) ? rawDesc.toString().trim() : null;

    final catImg = json['category_image'] ??
        json['mobile_image'] ??
        json['appImage'] ??
        json['app_image'] ??
        json['mobileImage'] ??
        json['image'] ??
        json['website_image'];

    final webImg = json['website_image'] ?? json['image'] ?? catImg;
    final icon = json['category_icon'] ?? json['icon'] ?? json['emoji'] ?? '🥛';

    final order = int.tryParse(json['display_order']?.toString() ?? '1') ?? 1;
    final active = json['is_active'] != null
        ? (json['is_active'] == true || json['is_active'].toString() == '1' || json['is_active'].toString() == 'true')
        : true;

    return CategoryModel(
      id: catId,
      categoryId: catId,
      categoryKey: catKey,
      name: catName,
      categoryName: catName,
      displayName: dispName.isNotEmpty ? dispName : catName,
      description: desc,
      categoryDescription: desc,
      categoryImage: catImg?.toString(),
      mobileImage: catImg?.toString(),
      websiteImage: webImg?.toString(),
      image: catImg?.toString() ?? webImg?.toString(),
      emoji: icon.toString(),
      categoryIcon: icon.toString(),
      isActive: active,
      displayOrder: order,
      itemCount: json['itemCount'] ?? json['item_count'] ?? 0,
      updatedAt: json['updated_at']?.toString(),
    );
  }

  /// Always returns resolved URL specifically for mobile app image
  String get mobileImageUrl {
    final path = categoryImage ?? mobileImage ?? image ?? '/assets/images/products/fresh_cow_milk.jpg';
    return ApiEndpoints.resolveImageUrl(path);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'category_key': categoryKey,
      'name': name,
      'category_name': categoryName,
      'displayName': displayName,
      'display_name': displayName,
      'description': description,
      'category_description': categoryDescription,
      'category_image': categoryImage,
      'mobile_image': mobileImage,
      'appImage': mobileImage,
      'website_image': websiteImage,
      'image': mobileImage,
      'emoji': emoji,
      'category_icon': categoryIcon,
      'is_active': isActive,
      'display_order': displayOrder,
      'itemCount': itemCount,
      'updated_at': updatedAt,
    };
  }
}

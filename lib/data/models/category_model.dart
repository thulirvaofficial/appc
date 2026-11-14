import '../../core/constants/api_endpoints.dart';

class CategoryModel {
  final dynamic id;
  final String name;
  final String displayName;
  final String? description;
  final String? mobileImage;
  final String? websiteImage;
  final String? image;
  final String? emoji;
  final bool isActive;
  final int displayOrder;
  final int itemCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.mobileImage,
    this.websiteImage,
    this.image,
    this.emoji,
    this.isActive = true,
    this.displayOrder = 1,
    this.itemCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // Priority: mobile_image / appImage explicitly uploaded for mobile apps
    final mobImg = json['mobile_image'] ??
        json['appImage'] ??
        json['app_image'] ??
        json['mobileImage'] ??
        json['image'];

    final webImg = json['website_image'] ?? json['image'];

    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? json['display_name'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      mobileImage: mobImg,
      websiteImage: webImg,
      image: mobImg ?? webImg,
      emoji: json['emoji'] ?? '🥛',
      isActive: json['is_active'] != null ? (json['is_active'] == true || json['is_active'].toString() == '1') : true,
      displayOrder: int.tryParse(json['display_order']?.toString() ?? '1') ?? 1,
      itemCount: json['itemCount'] ?? json['item_count'] ?? 0,
    );
  }

  /// Always returns resolved URL specifically for mobile app image
  String get mobileImageUrl {
    final path = mobileImage ?? image ?? '/assets/images/products/fresh_cow_milk.jpg';
    return ApiEndpoints.resolveImageUrl(path);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'description': description,
      'mobile_image': mobileImage,
      'appImage': mobileImage,
      'website_image': websiteImage,
      'image': mobileImage,
      'emoji': emoji,
      'is_active': isActive,
      'display_order': displayOrder,
      'itemCount': itemCount,
    };
  }
}

import '../../core/constants/api_endpoints.dart';

import '../../core/utils/safe_parse_util.dart';

class ProductVariantModel {
  final dynamic id;
  final dynamic productId;
  final String name;
  final String weightValue;
  final String unit;
  final double price;
  final double? comparePrice;
  final int stock;
  final bool isDefault;
  final bool isActive;

  ProductVariantModel({
    required this.id,
    this.productId,
    required this.name,
    this.weightValue = '',
    this.unit = 'g',
    required this.price,
    this.comparePrice,
    this.stock = 50,
    this.isDefault = false,
    this.isActive = true,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? json['productId'],
      name: json['name']?.toString() ?? 'Standard',
      weightValue: json['weight_value']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'g',
      price: SafeParseUtil.toDouble(json['price']),
      comparePrice: json['compare_price'] != null ? SafeParseUtil.toDouble(json['compare_price']) : null,
      stock: SafeParseUtil.toInt(json['stock'], 50),
      isDefault: json['is_default'] == true,
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'weight_value': weightValue,
      'unit': unit,
      'price': price,
      'compare_price': comparePrice,
      'stock': stock,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }
}

class ProductModel {
  final dynamic id;
  final String name;
  final String category;
  final String? categoryName;
  final double price;
  final double? comparePrice;
  final String weight;
  final int stock;
  final String? badge;
  final String? emoji;
  final String? image;
  final String? description;
  final String? shortDescription;
  final String status;
  final List<ProductVariantModel> variants;
  final List<dynamic> featureBadges;
  final List<String> highlights;
  final List<String> ingredients;
  final bool ingredientsEnabled;
  final Map<String, dynamic>? nutritionalInfo;
  final String storageInstructions;
  final String usageInstructions;
  final Map<String, dynamic>? refundPolicy;
  final String shelfLife;
  final String certification;
  final String? seoTitle;
  final String? seoDescription;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    this.categoryName,
    required this.price,
    this.comparePrice,
    this.weight = '',
    this.stock = 100,
    this.badge,
    this.emoji,
    this.image,
    this.description,
    this.shortDescription,
    this.status = 'active',
    this.variants = const [],
    this.featureBadges = const [],
    this.highlights = const [],
    this.ingredients = const [],
    this.ingredientsEnabled = true,
    this.nutritionalInfo,
    this.storageInstructions = '',
    this.usageInstructions = '',
    this.refundPolicy,
    this.shelfLife = '',
    this.certification = '',
    this.seoTitle,
    this.seoDescription,
  });

  ProductVariantModel? get defaultVariant {
    if (variants.isEmpty) return null;
    return variants.firstWhere(
      (v) => v.isDefault,
      orElse: () => variants.first,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final parsedId = json['id'] ?? json['product_id'] ?? 0;
    final parsedName = (json['name'] ?? json['title'] ?? json['product_name'] ?? 'Fresh Farm Product').toString();
    final parsedPrice = SafeParseUtil.toDouble(json['price']);
    final parsedWeight = (json['weight'] ?? '').toString();

    // Parse variants if provided by backend API
    List<ProductVariantModel> parsedVariants = [];
    if (json['variants'] is List && (json['variants'] as List).isNotEmpty) {
      parsedVariants = (json['variants'] as List)
          .map((v) => ProductVariantModel.fromJson(Map<String, dynamic>.from(v as Map)))
          .where((v) => v.isActive)
          .toList();
    }

    // Dynamic generation if backend hasn't assigned custom variants yet
    if (parsedVariants.isEmpty) {
      parsedVariants = _generateDefaultVariants(parsedId, parsedName, parsedPrice, parsedWeight);
    }

    final List<String> parsedHighlights = (json['highlights'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final List<String> parsedIngredients = (json['ingredients'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final Map<String, dynamic>? parsedNutrition = json['nutritional_info'] is Map
        ? Map<String, dynamic>.from(json['nutritional_info'] as Map)
        : null;
    final Map<String, dynamic>? parsedRefund = json['refund_policy'] is Map
        ? Map<String, dynamic>.from(json['refund_policy'] as Map)
        : null;

    return ProductModel(
      id: parsedId,
      name: parsedName,
      category: (json['category'] ?? json['category_name'] ?? 'Dairy').toString(),
      categoryName: json['category_name']?.toString() ?? json['category']?.toString(),
      price: parsedPrice,
      comparePrice: json['compare_price'] != null ? SafeParseUtil.toDouble(json['compare_price']) : null,
      weight: parsedWeight,
      stock: SafeParseUtil.toInt(json['stock'], 50),
      badge: json['badge']?.toString(),
      emoji: json['emoji']?.toString() ?? '🥛',
      image: json['image']?.toString() ?? json['image_url']?.toString(),
      description: json['description']?.toString(),
      shortDescription: json['short_description']?.toString(),
      status: (json['status'] ?? 'active').toString(),
      variants: parsedVariants,
      featureBadges: (json['feature_badges'] is List)
          ? List<dynamic>.from(json['feature_badges'] as List)
          : (json['features'] is List
              ? (json['features'] as List).map((f) => {'icon': '🌿', 'text': f.toString(), 'enabled': true}).toList()
              : const []),
      highlights: parsedHighlights,
      ingredients: parsedIngredients,
      ingredientsEnabled: json['ingredients_enabled'] != false,
      nutritionalInfo: parsedNutrition,
      storageInstructions: (json['storage_instructions'] ?? json['storage'] ?? '').toString(),
      usageInstructions: (json['usage_instructions'] ?? json['usage'] ?? '').toString(),
      refundPolicy: parsedRefund,
      shelfLife: (json['shelf_life'] ?? '').toString(),
      certification: (json['certification'] ?? '').toString(),
      seoTitle: json['seo_title']?.toString(),
      seoDescription: json['seo_description']?.toString(),
    );
  }

  static List<ProductVariantModel> _generateDefaultVariants(dynamic pid, String name, double basePrice, String weight) {
    final nameLower = name.toLowerCase();

    if (nameLower.contains('almond')) {
      return [
        ProductVariantModel(id: 101, productId: pid, name: '100g', weightValue: '100', unit: 'g', price: 120, comparePrice: 140, stock: 50, isDefault: true),
        ProductVariantModel(id: 102, productId: pid, name: '250g', weightValue: '250', unit: 'g', price: 280, comparePrice: 320, stock: 40),
        ProductVariantModel(id: 103, productId: pid, name: '500g', weightValue: '500', unit: 'g', price: 520, comparePrice: 600, stock: 35),
        ProductVariantModel(id: 104, productId: pid, name: '1kg', weightValue: '1', unit: 'kg', price: 990, comparePrice: 1150, stock: 20),
      ];
    }
    if (nameLower.contains('cashew')) {
      return [
        ProductVariantModel(id: 201, productId: pid, name: '200g', weightValue: '200', unit: 'g', price: 180, comparePrice: 210, stock: 45, isDefault: true),
        ProductVariantModel(id: 202, productId: pid, name: '500g', weightValue: '500', unit: 'g', price: 420, comparePrice: 480, stock: 30),
        ProductVariantModel(id: 203, productId: pid, name: '1kg', weightValue: '1', unit: 'kg', price: 800, comparePrice: 920, stock: 25),
      ];
    }
    if (nameLower.contains('honey')) {
      return [
        ProductVariantModel(id: 301, productId: pid, name: '250ml', weightValue: '250', unit: 'ml', price: 150, comparePrice: 180, stock: 30),
        ProductVariantModel(id: 302, productId: pid, name: '500ml', weightValue: '500', unit: 'ml', price: 280, comparePrice: 320, stock: 25, isDefault: true),
        ProductVariantModel(id: 303, productId: pid, name: '1 Litre', weightValue: '1', unit: 'litre', price: 520, comparePrice: 600, stock: 15),
      ];
    }
    if (nameLower.contains('milk')) {
      return [
        ProductVariantModel(id: 501, productId: pid, name: '500 ml', weightValue: '500', unit: 'ml', price: basePrice > 0 ? basePrice : 44, comparePrice: 50, stock: 120, isDefault: true),
        ProductVariantModel(id: 502, productId: pid, name: '1 Litre', weightValue: '1', unit: 'litre', price: basePrice > 0 ? (basePrice * 1.85).roundToDouble() : 82, comparePrice: 90, stock: 150),
      ];
    }
    if (nameLower.contains('ghee')) {
      return [
        ProductVariantModel(id: 601, productId: pid, name: '250 ml', weightValue: '250', unit: 'ml', price: 280, comparePrice: 320, stock: 40),
        ProductVariantModel(id: 602, productId: pid, name: '500 ml', weightValue: '500', unit: 'ml', price: basePrice > 0 ? basePrice : 520, comparePrice: 600, stock: 45, isDefault: true),
        ProductVariantModel(id: 603, productId: pid, name: '1 Litre', weightValue: '1', unit: 'litre', price: 990, comparePrice: 1150, stock: 20),
      ];
    }
    if (nameLower.contains('paneer') || nameLower.contains('tofu')) {
      return [
        ProductVariantModel(id: 701, productId: pid, name: '200 g', weightValue: '200', unit: 'g', price: basePrice > 0 ? basePrice : 82, comparePrice: 95, stock: 60, isDefault: true),
        ProductVariantModel(id: 702, productId: pid, name: '500 g', weightValue: '500', unit: 'g', price: basePrice > 0 ? (basePrice * 2.3).roundToDouble() : 190, comparePrice: 230, stock: 40),
        ProductVariantModel(id: 703, productId: pid, name: '1 kg', weightValue: '1', unit: 'kg', price: basePrice > 0 ? (basePrice * 4.4).roundToDouble() : 360, comparePrice: 440, stock: 20),
      ];
    }

    // Default variant
    final defaultWeight = weight.isNotEmpty ? weight : 'Standard';
    return [
      ProductVariantModel(id: 1, productId: pid, name: defaultWeight, weightValue: defaultWeight, unit: 'unit', price: basePrice, stock: 50, isDefault: true),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'category_name': categoryName,
      'price': price,
      'compare_price': comparePrice,
      'weight': weight,
      'stock': stock,
      'badge': badge,
      'emoji': emoji,
      'image': image,
      'description': description,
      'status': status,
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }

  String get fullImageUrl {
    if (image == null || image!.isEmpty) return '';
    if (image!.startsWith('http://') || image!.startsWith('https://')) {
      return image!;
    }
    final serverRoot = ApiEndpoints.baseUrl.replaceAll('/api', '');
    final cleanPath = image!.startsWith('/') ? image! : '/$image';
    return '$serverRoot$cleanPath';
  }
}

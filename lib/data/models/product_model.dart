import '../../core/constants/api_endpoints.dart';

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
  final String status;

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
    this.status = 'active',
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? json['category_name'] ?? 'Dairy',
      categoryName: json['category_name'] ?? json['category'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      comparePrice: json['compare_price'] != null ? double.tryParse(json['compare_price'].toString()) : null,
      weight: json['weight'] ?? '',
      stock: int.tryParse(json['stock'].toString()) ?? 50,
      badge: json['badge'],
      emoji: json['emoji'] ?? '🥛',
      image: json['image'],
      description: json['description'],
      status: json['status'] ?? 'active',
    );
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
    };
  }

  String get fullImageUrl {
    if (image == null || image!.isEmpty) return '';
    if (image!.startsWith('http://') || image!.startsWith('https://')) {
      return image!;
    }
    // Remove /api suffix from base url to serve static files from server root
    final serverRoot = ApiEndpoints.baseUrl.replaceAll('/api', '');
    final cleanPath = image!.startsWith('/') ? image! : '/$image';
    return '$serverRoot$cleanPath';
  }
}


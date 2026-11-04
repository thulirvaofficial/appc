import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  String? selectedVariant;
  ProductVariantModel? variant;
  double? overridePrice;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.selectedVariant,
    this.variant,
    this.overridePrice,
  });

  double get unitPrice {
    if (variant != null && variant!.price > 0) return variant!.price;
    if (overridePrice != null && overridePrice! > 0) return overridePrice!;
    return product.price;
  }

  double get totalPrice => unitPrice * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    ProductModel prod;
    try {
      if (json['product'] is Map) {
        prod = ProductModel.fromJson(Map<String, dynamic>.from(json['product'] as Map));
      } else {
        prod = ProductModel(
          id: json['product_id'] ?? json['id'] ?? 0,
          name: json['name'] ?? json['product_name'] ?? json['title'] ?? 'Fresh Farm Product',
          category: json['category'] ?? json['category_name'] ?? 'Dairy',
          price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
          image: json['image']?.toString() ?? json['image_url']?.toString(),
          weight: json['weight']?.toString() ?? '',
        );
      }
    } catch (_) {
      prod = ProductModel(
        id: json['product_id'] ?? json['id'] ?? 0,
        name: json['name'] ?? json['product_name'] ?? 'Fresh Farm Product',
        category: 'Dairy',
        price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
        image: json['image']?.toString(),
        weight: json['weight']?.toString() ?? '',
      );
    }

    final variantName = json['selectedVariant']?.toString() ?? json['variant_name']?.toString();
    ProductVariantModel? parsedVariant;

    if (json['variant'] is Map) {
      try {
        parsedVariant = ProductVariantModel.fromJson(Map<String, dynamic>.from(json['variant'] as Map));
      } catch (_) {}
    }

    if (parsedVariant == null && variantName != null && prod.variants.isNotEmpty) {
      parsedVariant = prod.variants.firstWhere(
        (v) => v.name.toLowerCase() == variantName.toLowerCase(),
        orElse: () => prod.variants.first,
      );
    }

    final double? unitP = double.tryParse((json['unit_price'] ?? json['unitPrice'] ?? json['price'] ?? '').toString());

    return CartItemModel(
      product: prod,
      quantity: int.tryParse((json['quantity'] ?? 1).toString()) ?? 1,
      selectedVariant: variantName ?? parsedVariant?.name ?? prod.weight,
      variant: parsedVariant,
      overridePrice: unitP,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'product_id': product.id,
      'name': product.name,
      'price': unitPrice,
      'unit_price': unitPrice,
      'image': product.image,
      'quantity': quantity,
      'selectedVariant': selectedVariant ?? variant?.name,
      'variant': variant?.toJson(),
    };
  }
}

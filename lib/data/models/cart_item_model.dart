import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  String? selectedVariant;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.selectedVariant,
  });

  double get totalPrice => product.price * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    ProductModel prod;
    try {
      if (json['product'] is Map) {
        prod = ProductModel.fromJson(Map<String, dynamic>.from(json['product'] as Map));
      } else {
        prod = ProductModel(
          id: json['product_id'] ?? json['id'] ?? 0,
          name: json['name'] ?? 'Fresh Farm Product',
          category: json['category'] ?? 'Dairy',
          price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
        );
      }
    } catch (_) {
      prod = ProductModel(
        id: json['product_id'] ?? 0,
        name: 'Fresh Farm Product',
        category: 'Dairy',
        price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      );
    }

    return CartItemModel(
      product: prod,
      quantity: int.tryParse((json['quantity'] ?? 1).toString()) ?? 1,
      selectedVariant: json['selectedVariant']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'selectedVariant': selectedVariant,
    };
  }
}

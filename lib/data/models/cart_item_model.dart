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
    return CartItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] ?? 1,
      selectedVariant: json['selectedVariant'],
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


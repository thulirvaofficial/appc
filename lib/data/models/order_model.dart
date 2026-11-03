class OrderModel {
  final dynamic id;
  final dynamic userId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final List<dynamic> items;
  final double subtotal;
  final double deliveryCharge;
  final double discountAmount;
  final String? promoCode;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String? transactionId;
  final String? paymentProof;
  final String createdAt;

  OrderModel({
    required this.id,
    this.userId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.address,
    required this.city,
    this.state = 'Tamil Nadu',
    required this.pincode,
    required this.items,
    this.subtotal = 0.0,
    this.deliveryCharge = 30.0,
    this.discountAmount = 0.0,
    this.promoCode,
    required this.total,
    this.paymentMethod = 'UPI Direct',
    this.paymentStatus = 'pending',
    this.orderStatus = 'pending',
    this.transactionId,
    this.paymentProof,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'],
      customerName: json['customer_name'] ?? json['customerName'] ?? 'Customer',
      customerPhone: json['customer_phone'] ?? json['customerPhone'] ?? '',
      customerEmail: json['customer_email'] ?? json['customerEmail'],
      address: json['address'] ?? '',
      city: json['city'] ?? 'Chennai',
      state: json['state'] ?? 'Tamil Nadu',
      pincode: json['pincode'] ?? '',
      items: json['items'] as List<dynamic>? ?? [],
      subtotal: double.tryParse((json['subtotal'] ?? 0).toString()) ?? 0.0,
      deliveryCharge: double.tryParse((json['delivery_charge'] ?? 30).toString()) ?? 30.0,
      discountAmount: double.tryParse((json['discount_amount'] ?? 0).toString()) ?? 0.0,
      promoCode: json['promo_code'],
      total: double.tryParse((json['total'] ?? json['total_price'] ?? 0).toString()) ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'UPI Direct',
      paymentStatus: json['payment_status'] ?? 'pending',
      orderStatus: json['order_status'] ?? 'pending',
      transactionId: json['transaction_id'] ?? json['transactionId'],
      paymentProof: json['payment_proof'] ?? json['paymentProof'],
      createdAt: json['created_at'] ?? DateTime.now().toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'items': items,
      'subtotal': subtotal,
      'delivery_charge': deliveryCharge,
      'discount_amount': discountAmount,
      'promo_code': promoCode,
      'total': total,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'order_status': orderStatus,
      'transaction_id': transactionId,
      'payment_proof': paymentProof,
      'created_at': createdAt,
    };
  }
}


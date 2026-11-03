class SubscriptionPlanModel {
  final dynamic id;
  final dynamic productId;
  final String productName;
  final String? productImage;
  final String timePeriod;
  final String frequency;
  final int durationDays;
  final double price;
  final double? originalPrice;
  final int discountPercent;
  final String description;
  final String badge;
  final String status;

  SubscriptionPlanModel({
    required this.id,
    this.productId,
    required this.productName,
    this.productImage,
    required this.timePeriod,
    this.frequency = 'Daily',
    this.durationDays = 30,
    required this.price,
    this.originalPrice,
    this.discountPercent = 0,
    required this.description,
    this.badge = 'Popular',
    this.status = 'active',
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] ?? 0,
      productId: json['product_id'],
      productName: json['product_name'] ?? 'Farm Fresh Product',
      productImage: json['product_image'],
      timePeriod: json['time_period'] ?? 'Daily Morning (30 Days)',
      frequency: json['frequency'] ?? 'Daily',
      durationDays: int.tryParse((json['duration_days'] ?? 30).toString()) ?? 30,
      price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      originalPrice: json['original_price'] != null ? double.tryParse(json['original_price'].toString()) : null,
      discountPercent: int.tryParse((json['discount_percent'] ?? 0).toString()) ?? 0,
      description: json['description'] ?? '',
      badge: json['badge'] ?? 'Popular',
      status: json['status'] ?? 'active',
    );
  }
}

class SubscriptionModel {
  final String id;
  final dynamic userId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String productName;
  final String? productImage;
  final String timePeriod;
  final String frequency;
  final int quantity;
  final String deliverySlot;
  final double pricePerDelivery;
  final double totalPrice;
  final String startDate;
  final String? expiryDate;
  final int daysRemaining;
  final String address;
  final String status;
  final String? transactionId;
  final String? paymentProof;

  SubscriptionModel({
    required this.id,
    this.userId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.productName,
    this.productImage,
    required this.timePeriod,
    this.frequency = 'Daily',
    this.quantity = 1,
    this.deliverySlot = '6:00 AM - 7:00 AM',
    required this.pricePerDelivery,
    required this.totalPrice,
    required this.startDate,
    this.expiryDate,
    this.daysRemaining = 30,
    required this.address,
    this.status = 'Active',
    this.transactionId,
    this.paymentProof,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final startStr = json['start_date'] ?? json['startDate'] ?? DateTime.now().toString().split(' ')[0];
    DateTime? startDateObj;
    try {
      startDateObj = DateTime.tryParse(startStr);
    } catch (_) {}

    final duration = json['duration_days'] ?? (json['time_period']?.toString().contains('15') == true ? 15 : 30);
    DateTime? expiryDateObj;
    if (json['expiry_date'] != null) {
      expiryDateObj = DateTime.tryParse(json['expiry_date']);
    } else if (startDateObj != null) {
      expiryDateObj = startDateObj.add(Duration(days: duration));
    }

    int remaining = 0;
    if (expiryDateObj != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiryOnly = DateTime(expiryDateObj.year, expiryDateObj.month, expiryDateObj.day);
      remaining = expiryOnly.difference(today).inDays;
    }

    return SubscriptionModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? json['userId'],
      customerName: json['customer_name'] ?? json['customerName'] ?? 'Customer',
      customerPhone: json['customer_phone'] ?? json['customerPhone'] ?? '',
      customerEmail: json['customer_email'] ?? json['customerEmail'],
      productName: json['product_name'] ?? json['productName'] ?? 'Fresh Cow Milk',
      productImage: json['product_image'] ?? json['productImage'],
      timePeriod: json['time_period'] ?? json['timePeriod'] ?? 'Daily (30 Days)',
      frequency: json['frequency'] ?? 'Daily',
      quantity: int.tryParse((json['quantity'] ?? 1).toString()) ?? 1,
      deliverySlot: json['delivery_slot'] ?? json['deliverySlot'] ?? '6:00 AM - 7:00 AM',
      pricePerDelivery: double.tryParse((json['price_per_delivery'] ?? 44).toString()) ?? 44.0,
      totalPrice: double.tryParse((json['total_price'] ?? json['totalPrice'] ?? 0).toString()) ?? 0.0,
      startDate: startStr,
      expiryDate: expiryDateObj != null ? expiryDateObj.toString().split(' ')[0] : null,
      daysRemaining: remaining,
      address: json['address'] ?? '',
      status: json['status'] ?? 'Active',
      transactionId: json['transaction_id'] ?? json['transactionId'],
      paymentProof: json['payment_proof'] ?? json['paymentProof'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'product_name': productName,
      'product_image': productImage,
      'time_period': timePeriod,
      'frequency': frequency,
      'quantity': quantity,
      'delivery_slot': deliverySlot,
      'price_per_delivery': pricePerDelivery,
      'total_price': totalPrice,
      'start_date': startDate,
      'expiry_date': expiryDate,
      'address': address,
      'status': status,
      'transaction_id': transactionId,
      'payment_proof': paymentProof,
    };
  }
}


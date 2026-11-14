import '../../core/utils/safe_parse_util.dart';
import 'order_model.dart';

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

  String get name => productName;

  SubscriptionPlanModel({
    required this.id,
    this.productId,
    String? productName,
    String? name,
    this.productImage,
    required this.timePeriod,
    this.frequency = 'Daily',
    this.durationDays = 30,
    required this.price,
    this.originalPrice,
    this.discountPercent = 0,
    this.description = '',
    this.badge = 'Popular',
    this.status = 'active',
  }) : productName = productName ?? name ?? 'Farm Fresh Product';

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] ?? 0,
      productId: json['product_id'],
      productName: json['product_name'] ?? 'Farm Fresh Product',
      productImage: json['product_image'],
      timePeriod: json['time_period'] ?? 'Daily Morning (30 Days)',
      frequency: json['frequency'] ?? 'Daily',
      durationDays: SafeParseUtil.toInt(json['duration_days'], 30),
      price: SafeParseUtil.toDouble(json['price']),
      originalPrice: json['original_price'] != null ? SafeParseUtil.toDouble(json['original_price']) : null,
      discountPercent: SafeParseUtil.toInt(json['discount_percent']),
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
  final String? nextRenewalDate;
  final int daysRemaining;
  final String address;
  final String paymentStatus;
  final String status;
  final String? transactionId;
  final String? paymentProof;
  final String? rejectionReason;
  final String? notes;
  final String? createdAt;

  double get totalAmount => totalPrice;
  String get purchaseDate => createdAt ?? startDate;
  DateTime? get createdDateTime => DateTime.tryParse(createdAt ?? startDate);
  bool get isActive => status.toLowerCase() == 'active';
  bool get isPaused => status.toLowerCase() == 'paused';
  bool get isExpired => status.toLowerCase() == 'expired' || (daysRemaining <= 0 && status.toLowerCase() != 'cancelled' && status.toLowerCase() != 'paused');
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isRejected => status.toLowerCase() == 'rejected' || paymentStatus.toLowerCase() == 'rejected';
  bool get isPendingApproval => status.toLowerCase().contains('pending') || paymentStatus.toLowerCase().contains('pending');

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
    this.nextRenewalDate,
    this.daysRemaining = 30,
    required this.address,
    this.paymentStatus = 'Pending',
    this.status = 'Active',
    this.transactionId,
    this.paymentProof,
    this.rejectionReason,
    this.notes,
    this.createdAt,
  });

  SubscriptionModel copyWith({
    String? id,
    dynamic userId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? productName,
    String? productImage,
    String? timePeriod,
    String? frequency,
    int? quantity,
    String? deliverySlot,
    double? pricePerDelivery,
    double? totalPrice,
    String? startDate,
    String? expiryDate,
    String? nextRenewalDate,
    int? daysRemaining,
    String? address,
    String? paymentStatus,
    String? status,
    String? transactionId,
    String? paymentProof,
    String? rejectionReason,
    String? notes,
    String? createdAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      timePeriod: timePeriod ?? this.timePeriod,
      frequency: frequency ?? this.frequency,
      quantity: quantity ?? this.quantity,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      pricePerDelivery: pricePerDelivery ?? this.pricePerDelivery,
      totalPrice: totalPrice ?? this.totalPrice,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      address: address ?? this.address,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      paymentProof: paymentProof ?? this.paymentProof,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final startStr = json['start_date'] ?? json['startDate'] ?? DateTime.now().toString().split(' ')[0];
    DateTime? startDateObj;
    try {
      startDateObj = DateTime.tryParse(startStr);
    } catch (_) {}

    final int duration = int.tryParse(json['duration_days']?.toString() ?? '') ?? (json['time_period']?.toString().contains('15') == true ? 15 : 30);
    DateTime? expiryDateObj;
    if (json['expiry_date'] != null && json['expiry_date'].toString().isNotEmpty) {
      expiryDateObj = DateTime.tryParse(json['expiry_date'].toString());
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

    final expiryFormatted = expiryDateObj != null ? expiryDateObj.toString().split(' ')[0] : null;

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
      quantity: SafeParseUtil.toInt(json['quantity'], 1),
      deliverySlot: json['delivery_slot'] ?? json['deliverySlot'] ?? '6:00 AM - 7:00 AM',
      pricePerDelivery: SafeParseUtil.toDouble(json['price_per_delivery'], 44.0),
      totalPrice: SafeParseUtil.toDouble(json['total_price'] ?? json['totalPrice']),
      startDate: startStr,
      expiryDate: expiryFormatted,
      nextRenewalDate: json['next_renewal_date'] ?? json['nextRenewalDate'] ?? expiryFormatted,
      daysRemaining: remaining,
      address: json['address'] ?? '',
      paymentStatus: json['payment_status'] ?? json['paymentStatus'] ?? 'Pending',
      status: json['status'] ?? 'Active',
      transactionId: json['transaction_id'] ?? json['transactionId'],
      paymentProof: json['payment_proof'] ?? json['paymentProof'],
      rejectionReason: json['rejection_reason'] ?? json['rejectionReason'],
      notes: json['notes'],
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString() ?? json['purchase_date']?.toString() ?? startStr,
    );
  }

  OrderModel toOrderModel() {
    final cleanCity = address.toLowerCase().contains('thiruverkadu') ? 'Thiruverkadu' : 'Thiruverkadu';
    return OrderModel(
      id: id,
      userId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      address: address.isNotEmpty ? address : 'Door No. 12, Farm Lane, Thiruverkadu',
      city: cleanCity,
      pincode: '600077',
      items: [
        {
          'name': productName,
          'quantity': quantity,
          'price': pricePerDelivery,
        }
      ],
      subtotal: totalPrice,
      deliveryCharge: 0.0,
      total: totalPrice,
      paymentMethod: 'UPI',
      paymentStatus: paymentStatus,
      orderStatus: status.toLowerCase() == 'active' ? 'out_for_delivery' : status,
      createdAt: startDate,
      partnerName: 'Kumar R',
      partnerPhone: '9840515293',
      partnerVehicle: 'Electric Scooter • TN 09 CY 4567',
      partnerRating: 4.8,
      partnerLatitude: 12.8055,
      partnerLongitude: 80.2260,
      latitude: 12.8090,
      longitude: 80.2280,
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
      'next_renewal_date': nextRenewalDate,
      'address': address,
      'payment_status': paymentStatus,
      'status': status,
      'transaction_id': transactionId,
      'payment_proof': paymentProof,
      'rejection_reason': rejectionReason,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}


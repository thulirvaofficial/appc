import '../../core/utils/id_formatter.dart';

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
  final String deliveryType;
  final bool isPickup;
  final String? pickupSlot;
  final String? pickupLocationName;
  final String? orderNumber;
  final String? partnerId;
  final String? partnerName;
  final String? partnerPhone;
  final String? partnerPhoto;
  final String? partnerVehicle;
  final double? partnerRating;
  final double? partnerLatitude;
  final double? partnerLongitude;
  final double? rating;
  final String? feedback;
  final double? latitude;
  final double? longitude;
  final String? deliveryProofUrl;
  final String? deliveredAt;

  dynamic get orderId => orderNumber ?? id;
  String get formattedOrderId => IdFormatter.formatOrderId(orderNumber ?? id);
  String get formattedCustomerId => IdFormatter.formatCustomerId(userId);
  double get totalPrice => total;

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
    this.deliveryType = 'delivery',
    this.isPickup = false,
    this.pickupSlot,
    this.pickupLocationName,
    this.orderNumber,
    this.partnerId,
    this.partnerName,
    this.partnerPhone,
    this.partnerPhoto,
    this.partnerVehicle,
    this.partnerRating,
    this.partnerLatitude,
    this.partnerLongitude,
    this.rating,
    this.feedback,
    this.latitude,
    this.longitude,
    this.deliveryProofUrl,
    this.deliveredAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final dType = (json['delivery_type'] ?? json['order_type'] ?? 'delivery').toString().toLowerCase();
    final isPick = json['is_pickup'] == true || dType == 'pickup';

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
      promoCode: json['promo_code'] ?? json['coupon_code'],
      total: double.tryParse((json['total'] ?? json['total_price'] ?? json['total_amount'] ?? 0).toString()) ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'UPI Direct',
      paymentStatus: json['payment_status'] ?? 'pending',
      orderStatus: json['order_status'] ?? json['status'] ?? 'pending',
      transactionId: json['transaction_id'] ?? json['transactionId'],
      paymentProof: json['payment_proof'] ?? json['paymentProof'],
      createdAt: json['created_at'] ?? DateTime.now().toString(),
      deliveryType: dType,
      isPickup: isPick,
      pickupSlot: json['pickup_slot']?.toString(),
      pickupLocationName: json['pickup_location_name']?.toString(),
      orderNumber: json['order_number']?.toString(),
      partnerId: json['partner_id']?.toString(),
      partnerName: json['partner_name']?.toString(),
      partnerPhone: json['partner_phone']?.toString(),
      partnerPhoto: json['partner_photo']?.toString(),
      partnerVehicle: json['partner_vehicle']?.toString(),
      partnerRating: double.tryParse((json['partner_rating'] ?? 5.0).toString()),
      partnerLatitude: json['partner_latitude'] != null ? double.tryParse(json['partner_latitude'].toString()) : null,
      partnerLongitude: json['partner_longitude'] != null ? double.tryParse(json['partner_longitude'].toString()) : null,
      rating: double.tryParse((json['rating'] ?? 0).toString()),
      feedback: json['feedback']?.toString(),
      latitude: double.tryParse((json['latitude'] ?? '').toString()),
      longitude: double.tryParse((json['longitude'] ?? '').toString()),
      deliveryProofUrl: json['delivery_proof_url'] ?? json['delivery_proof'] ?? json['proof_url'],
      deliveredAt: json['delivered_at'] ?? json['delivery_proof_timestamp'],
    );
  }

  OrderModel copyWith({
    dynamic id,
    dynamic userId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? address,
    String? city,
    String? state,
    String? pincode,
    List<dynamic>? items,
    double? subtotal,
    double? deliveryCharge,
    double? discountAmount,
    String? promoCode,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    String? orderStatus,
    String? transactionId,
    String? paymentProof,
    String? createdAt,
    String? deliveryType,
    bool? isPickup,
    String? pickupSlot,
    String? pickupLocationName,
    String? orderNumber,
    String? partnerId,
    String? partnerName,
    String? partnerPhone,
    String? partnerPhoto,
    String? partnerVehicle,
    double? partnerRating,
    double? partnerLatitude,
    double? partnerLongitude,
    double? rating,
    String? feedback,
    double? latitude,
    double? longitude,
    String? deliveryProofUrl,
    String? deliveredAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      discountAmount: discountAmount ?? this.discountAmount,
      promoCode: promoCode ?? this.promoCode,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      transactionId: transactionId ?? this.transactionId,
      paymentProof: paymentProof ?? this.paymentProof,
      createdAt: createdAt ?? this.createdAt,
      deliveryType: deliveryType ?? this.deliveryType,
      isPickup: isPickup ?? this.isPickup,
      pickupSlot: pickupSlot ?? this.pickupSlot,
      pickupLocationName: pickupLocationName ?? this.pickupLocationName,
      orderNumber: orderNumber ?? this.orderNumber,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      partnerPhone: partnerPhone ?? this.partnerPhone,
      partnerPhoto: partnerPhoto ?? this.partnerPhoto,
      partnerVehicle: partnerVehicle ?? this.partnerVehicle,
      partnerRating: partnerRating ?? this.partnerRating,
      partnerLatitude: partnerLatitude ?? this.partnerLatitude,
      partnerLongitude: partnerLongitude ?? this.partnerLongitude,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deliveryProofUrl: deliveryProofUrl ?? this.deliveryProofUrl,
      deliveredAt: deliveredAt ?? this.deliveredAt,
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
      'delivery_type': deliveryType,
      'is_pickup': isPickup,
      'pickup_slot': pickupSlot,
      'pickup_location_name': pickupLocationName,
      'order_number': orderNumber,
    };
  }
}

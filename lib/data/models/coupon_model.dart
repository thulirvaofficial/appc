class CouponModel {
  final dynamic id;
  final String code;
  final String discountType; // 'percent' or 'flat'
  final double discountValue;
  final double minOrder;
  final double? maxDiscount;
  final String description;
  final String expiryDate;
  final String status;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrder = 0,
    this.maxDiscount,
    required this.description,
    this.expiryDate = '2027-12-31',
    this.status = 'active',
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      discountType: json['discount_type'] ?? json['type'] ?? 'percent',
      discountValue: double.tryParse((json['discount_value'] ?? json['value'] ?? 0).toString()) ?? 0.0,
      minOrder: double.tryParse((json['min_order'] ?? 0).toString()) ?? 0.0,
      maxDiscount: json['max_discount'] != null ? double.tryParse(json['max_discount'].toString()) : null,
      description: json['description'] ?? '',
      expiryDate: json['expiry_date'] ?? '2027-12-31',
      status: json['status'] ?? 'active',
    );
  }

  String get discountBadgeText {
    if (discountType == 'percent') {
      return '${discountValue.toInt()}% OFF';
    } else {
      return '₹${discountValue.toInt()} OFF';
    }
  }
}


class ServiceableAreaModel {
  final dynamic id;
  final String areaName;
  final String city;
  final String state;
  final String pincode;
  final String boundaryType;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isServiceable;
  final bool isActive;
  final double deliveryCharge;
  final double minimumOrderAmount;
  final String estimatedDeliveryTime;

  const ServiceableAreaModel({
    required this.id,
    required this.areaName,
    required this.city,
    this.state = 'Tamil Nadu',
    required this.pincode,
    this.boundaryType = 'polygon',
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 5000,
    this.isServiceable = true,
    this.isActive = true,
    this.deliveryCharge = 0.0,
    this.minimumOrderAmount = 0.0,
    this.estimatedDeliveryTime = '30-45 minutes',
  });

  factory ServiceableAreaModel.fromJson(Map<String, dynamic> json) {
    return ServiceableAreaModel(
      id: json['id'],
      areaName: json['area_name'] ?? json['name'] ?? '',
      city: json['city'] ?? 'Chennai',
      state: json['state'] ?? 'Tamil Nadu',
      pincode: (json['pincode'] ?? '').toString(),
      boundaryType: json['boundary_type'] ?? 'polygon',
      latitude: (json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null) ?? 13.0827,
      longitude: (json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null) ?? 80.2707,
      radiusMeters: (json['radius_meters'] != null ? double.tryParse(json['radius_meters'].toString()) : null) ?? 5000.0,
      isServiceable: json['is_serviceable'] ?? true,
      isActive: json['is_active'] ?? true,
      deliveryCharge: (json['delivery_charge'] != null ? double.tryParse(json['delivery_charge'].toString()) : null) ??
          (json['deliveryCharge'] != null ? double.tryParse(json['deliveryCharge'].toString()) : null) ?? 0.0,
      minimumOrderAmount: (json['minimum_order_amount'] != null ? double.tryParse(json['minimum_order_amount'].toString()) : null) ??
          (json['minimumOrderAmount'] != null ? double.tryParse(json['minimumOrderAmount'].toString()) : null) ?? 0.0,
      estimatedDeliveryTime: json['estimated_delivery_time'] ?? json['estimatedDeliveryTime'] ?? '30-45 minutes',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area_name': areaName,
      'city': city,
      'state': state,
      'pincode': pincode,
      'boundary_type': boundaryType,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'is_serviceable': isServiceable,
      'is_active': isActive,
      'delivery_charge': deliveryCharge,
      'minimum_order_amount': minimumOrderAmount,
      'estimated_delivery_time': estimatedDeliveryTime,
    };
  }
}

class ServiceabilityCheckResult {
  final bool success;
  final bool serviceable;
  final String message;
  final ServiceableAreaModel? area;
  final String? matchType;

  const ServiceabilityCheckResult({
    required this.success,
    required this.serviceable,
    required this.message,
    this.area,
    this.matchType,
  });

  factory ServiceabilityCheckResult.fromJson(Map<String, dynamic> json) {
    return ServiceabilityCheckResult(
      success: json['success'] == true,
      serviceable: json['serviceable'] == true,
      message: json['message'] ?? (json['serviceable'] == true ? 'Available for Delivery' : 'Coming Soon'),
      matchType: json['matchType'],
      area: json['area'] != null ? ServiceableAreaModel.fromJson(json['area'] as Map<String, dynamic>) : null,
    );
  }
}


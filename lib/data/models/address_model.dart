class AddressModel {
  final dynamic id;
  final dynamic userId;
  final String name;
  final String phone;
  final String address;
  final String street;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String landmark;
  final String deliveryInstructions;
  final double? latitude;
  final double? longitude;
  final dynamic serviceableAreaId;
  final bool isServiceable;
  final bool isDefault;

  AddressModel({
    required this.id,
    this.userId,
    required this.name,
    required this.phone,
    required this.address,
    this.street = '',
    this.area = '',
    this.city = 'Chennai',
    this.state = 'Tamil Nadu',
    required this.pincode,
    this.landmark = '',
    this.deliveryInstructions = '',
    this.latitude,
    this.longitude,
    this.serviceableAreaId,
    this.isServiceable = true,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? json['userId'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? 'Chennai',
      state: json['state'] ?? 'Tamil Nadu',
      pincode: (json['pincode'] ?? '').toString(),
      landmark: json['landmark'] ?? '',
      deliveryInstructions: json['delivery_instructions'] ?? json['deliveryInstructions'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      serviceableAreaId: json['serviceable_area_id'] ?? json['serviceableAreaId'],
      isServiceable: json['is_serviceable'] ?? json['isServiceable'] ?? true,
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'street': street,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'delivery_instructions': deliveryInstructions,
      'latitude': latitude,
      'longitude': longitude,
      'serviceable_area_id': serviceableAreaId,
      'is_serviceable': isServiceable,
      'is_default': isDefault,
    };
  }

  AddressModel copyWith({
    dynamic id,
    dynamic userId,
    String? name,
    String? phone,
    String? address,
    String? street,
    String? area,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    String? deliveryInstructions,
    double? latitude,
    double? longitude,
    dynamic serviceableAreaId,
    bool? isServiceable,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      street: street ?? this.street,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceableAreaId: serviceableAreaId ?? this.serviceableAreaId,
      isServiceable: isServiceable ?? this.isServiceable,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get fullAddressString {
    final parts = [address, area, city, '$state - $pincode'];
    return parts.where((p) => p.trim().isNotEmpty).join(', ');
  }
}

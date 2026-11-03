class AddressModel {
  final dynamic id;
  final dynamic userId;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  AddressModel({
    required this.id,
    this.userId,
    required this.name,
    required this.phone,
    required this.address,
    this.city = 'Chennai',
    this.state = 'Tamil Nadu',
    required this.pincode,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? json['userId'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? 'Chennai',
      state: json['state'] ?? 'Tamil Nadu',
      pincode: json['pincode'] ?? '',
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
      'city': city,
      'state': state,
      'pincode': pincode,
      'is_default': isDefault,
    };
  }

  String get fullAddressString => '$address, $city, $state - $pincode';
}


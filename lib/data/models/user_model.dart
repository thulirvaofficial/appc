class UserModel {
  final dynamic id;
  final String name;
  final String email;
  final String? phone;
  final String? alternatePhone;
  final String? address;
  final String? city;
  final String? pincode;
  final String? profilePhoto;
  final String role;
  final String? token;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.alternatePhone,
    this.address,
    this.city,
    this.pincode,
    this.profilePhoto,
    this.role = 'customer',
    this.token,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? 1,
      name: json['name'] ?? 'THULIRVA Customer',
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
      alternatePhone: (json['alternate_phone'] ?? json['alternatePhone'])?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString() ?? 'Kanchipuram',
      pincode: json['pincode']?.toString() ?? '631601',
      profilePhoto: (json['profile_photo'] ?? json['profilePhoto'] ?? json['image'])?.toString(),
      role: json['role'] ?? 'customer',
      token: token ?? json['token'],
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'address': address,
      'city': city,
      'pincode': pincode,
      'profile_photo': profilePhoto,
      'role': role,
      'token': token,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    dynamic id,
    String? name,
    String? email,
    String? phone,
    String? alternatePhone,
    String? address,
    String? city,
    String? pincode,
    String? profilePhoto,
    String? role,
    String? token,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      address: address ?? this.address,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      role: role ?? this.role,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


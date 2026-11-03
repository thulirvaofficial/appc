class UserModel {
  final dynamic id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String role;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.role = 'customer',
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? 1,
      name: json['name'] ?? 'THULIRVA Customer',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      role: json['role'] ?? 'customer',
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'token': token,
    };
  }

  UserModel copyWith({
    dynamic id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? role,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }
}


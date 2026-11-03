class NotificationModel {
  final String id;
  final dynamic userId;
  final String type; // 'order_status', 'subscription_expiry', 'promotion', 'new_product'
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? json['userId'],
      type: json['type'] ?? 'general',
      title: json['title'] ?? 'THULIRVA Notification',
      message: json['message'] ?? '',
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null,
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt: json['created_at'] ?? DateTime.now().toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }
}


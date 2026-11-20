class NotificationModel {
  final String id;
  final dynamic userId;
  final String type; // 'order_status', 'subscription_expiry', 'promotion', 'new_product'
  final String title;
  final String message;
  final String? targetId;
  final Map<String, dynamic>? data;
  bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.targetId,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedData;
    if (json['data'] is Map<String, dynamic>) {
      parsedData = Map<String, dynamic>.from(json['data'] as Map<String, dynamic>);
    } else if (json['data'] is Map) {
      parsedData = Map<String, dynamic>.from(json['data'] as Map);
    }

    final tId = json['target_id']?.toString() ??
        json['targetId']?.toString() ??
        json['subscription_id']?.toString() ??
        parsedData?['subscription_id']?.toString() ??
        parsedData?['target_id']?.toString() ??
        parsedData?['targetId']?.toString();

    if (tId != null && tId.isNotEmpty) {
      parsedData ??= {};
      parsedData['target_id'] = tId;
      parsedData['subscription_id'] = tId;
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? json['userId'],
      type: json['type'] ?? 'general',
      title: json['title'] ?? 'THULIRVA Notification',
      message: json['message'] ?? '',
      targetId: tId,
      data: parsedData,
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
      'target_id': targetId,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }
}


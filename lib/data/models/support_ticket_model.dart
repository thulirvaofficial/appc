class SupportTicketModel {
  final int id;
  final String ticketId;
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String userType;
  final String category;
  final String subject;
  final String description;
  final String? orderId;
  final String priority;
  final String status;
  final String? assignedAgent;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<SupportMessageModel> messages;

  SupportTicketModel({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    required this.userType,
    required this.category,
    required this.subject,
    required this.description,
    this.orderId,
    required this.priority,
    required this.status,
    this.assignedAgent,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    var rawMsgs = json['messages'] as List?;
    List<SupportMessageModel> parsedMsgs = [];
    if (rawMsgs != null) {
      parsedMsgs = rawMsgs
          .map((m) => SupportMessageModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return SupportTicketModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      ticketId: json['ticket_id'] ?? json['ticket_number'] ?? '',
      userId: '${json['user_id'] ?? ''}',
      userName: json['user_name'] ?? 'User',
      userPhone: json['user_phone'] ?? '',
      userEmail: json['user_email'] ?? '',
      userType: json['user_type'] ?? 'customer',
      category: json['category'] ?? 'General',
      subject: json['subject'] ?? 'No Subject',
      description: json['description'] ?? '',
      orderId: json['order_id']?.toString(),
      priority: json['priority'] ?? 'NORMAL',
      status: json['status'] ?? 'OPEN',
      assignedAgent: json['assigned_agent'] ?? json['assigned_admin_name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse('${json['created_at']}') ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse('${json['updated_at']}')
          : null,
      messages: parsedMsgs,
    );
  }
}

class SupportMessageModel {
  final int id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final String? attachmentUrl;
  final DateTime createdAt;

  SupportMessageModel({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportMessageModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      ticketId: json['ticket_id'] ?? '',
      senderId: '${json['sender_id'] ?? ''}',
      senderName: json['sender_name'] ?? 'Support',
      senderRole: json['sender_role'] ?? 'user',
      message: json['message'] ?? '',
      attachmentUrl: json['attachment_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse('${json['created_at']}') ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isAdmin =>
      senderRole == 'admin' ||
      senderRole == 'support_agent' ||
      senderRole == 'operations';
}


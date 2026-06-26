class NotificationModel {
  final String id;
  final String title;
  final String content;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String userId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.data,
    required this.isRead,
    required this.userId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null,
      isRead: json['isRead'] == true || json['is_read'] == true,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    String? userId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.role,
    required super.content,
    required super.timestamp,
    super.isTyping,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String).toLowerCase();
    MessageRole mappedRole;
    if (roleStr == 'user') {
      mappedRole = MessageRole.user;
    } else if (roleStr == 'customer') {
      mappedRole = MessageRole.customer;
    } else if (roleStr == 'technician') {
      mappedRole = MessageRole.technician;
    } else if (roleStr == 'system') {
      mappedRole = MessageRole.system;
    } else {
      mappedRole = MessageRole.bot;
    }

    return ChatMessageModel(
      id: json['id'] as String,
      role: mappedRole,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'createdAt': timestamp.toIso8601String(),
      };

  static ChatMessageModel typingIndicator() => ChatMessageModel(
        id: 'typing',
        role: MessageRole.bot,
        content: '',
        timestamp: DateTime.now(),
        isTyping: true,
      );

  static ChatMessageModel botMessage({
    required String id,
    required String content,
  }) =>
      ChatMessageModel(
        id: id,
        role: MessageRole.bot,
        content: content,
        timestamp: DateTime.now(),
      );

  static ChatMessageModel userMessage({
    required String id,
    required String content,
  }) =>
      ChatMessageModel(
        id: id,
        role: MessageRole.user,
        content: content,
        timestamp: DateTime.now(),
      );
}

import '../../domain/entities/tech_chat_message.dart';

class TechChatMessageModel extends TechChatMessage {
  const TechChatMessageModel({
    required super.id,
    required super.role,
    required super.content,
    required super.timestamp,
    super.isTyping,
  });

  factory TechChatMessageModel.fromJson(Map<String, dynamic> json) {
    return TechChatMessageModel(
      id: json['id'] as String,
      role: TechMessageRole.values.firstWhere((e) => e.name == json['role']),
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

  static TechChatMessageModel typingIndicator() => TechChatMessageModel(
        id: 'typing',
        role: TechMessageRole.bot,
        content: '',
        timestamp: DateTime.now(),
        isTyping: true,
      );

  static TechChatMessageModel botMessage({
    required String id,
    required String content,
  }) =>
      TechChatMessageModel(
        id: id,
        role: TechMessageRole.bot,
        content: content,
        timestamp: DateTime.now(),
      );

  static TechChatMessageModel userMessage({
    required String id,
    required String content,
  }) =>
      TechChatMessageModel(
        id: id,
        role: TechMessageRole.user,
        content: content,
        timestamp: DateTime.now(),
      );
}

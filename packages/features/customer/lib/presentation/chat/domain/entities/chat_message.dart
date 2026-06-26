import 'package:equatable/equatable.dart';

enum MessageRole { user, bot, system }

class ChatMessage extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isTyping;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isTyping = false,
  });

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isTyping,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [id, role, content, timestamp, isTyping];
}

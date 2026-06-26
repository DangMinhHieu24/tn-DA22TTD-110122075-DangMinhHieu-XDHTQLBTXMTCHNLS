import 'package:equatable/equatable.dart';

enum TechMessageRole { user, bot, system }

class TechChatMessage extends Equatable {
  final String id;
  final TechMessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isTyping;

  const TechChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isTyping = false,
  });

  TechChatMessage copyWith({
    String? id,
    TechMessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isTyping,
  }) {
    return TechChatMessage(
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

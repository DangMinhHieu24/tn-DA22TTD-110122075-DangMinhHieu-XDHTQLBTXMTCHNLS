import 'package:equatable/equatable.dart';
import '../domain/entities/tech_chat_message.dart';

abstract class TechChatState extends Equatable {
  const TechChatState();

  @override
  List<Object?> get props => [];
}

class TechChatInitial extends TechChatState {}

class TechChatLoading extends TechChatState {}

class TechChatLoaded extends TechChatState {
  final List<TechChatMessage> messages;
  final bool isTyping;
  final int unreadCount;

  const TechChatLoaded({
    required this.messages,
    this.isTyping = false,
    this.unreadCount = 0,
  });

  TechChatLoaded copyWith({
    List<TechChatMessage>? messages,
    bool? isTyping,
    int? unreadCount,
  }) {
    return TechChatLoaded(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [messages, isTyping, unreadCount];
}

class TechChatError extends TechChatState {
  final String message;
  const TechChatError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../domain/entities/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final int unreadCount;

  const ChatLoaded({
    required this.messages,
    this.isTyping = false,
    this.unreadCount = 0,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    int? unreadCount,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [messages, isTyping, unreadCount];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

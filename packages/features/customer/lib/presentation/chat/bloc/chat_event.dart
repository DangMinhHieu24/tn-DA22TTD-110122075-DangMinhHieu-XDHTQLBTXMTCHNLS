import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatLoadHistory extends ChatEvent {}

class ChatSendMessage extends ChatEvent {
  final String content;
  const ChatSendMessage(this.content);

  @override
  List<Object?> get props => [content];
}

class ChatClearHistory extends ChatEvent {}

class ChatTypingStopped extends ChatEvent {}

class ChatUpdateUnreadCount extends ChatEvent {
  final int count;
  const ChatUpdateUnreadCount(this.count);

  @override
  List<Object?> get props => [count];
}

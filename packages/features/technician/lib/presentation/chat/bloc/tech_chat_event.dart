import 'package:equatable/equatable.dart';

abstract class TechChatEvent extends Equatable {
  const TechChatEvent();

  @override
  List<Object?> get props => [];
}

class TechChatLoadHistory extends TechChatEvent {}

class TechChatSendMessage extends TechChatEvent {
  final String content;
  const TechChatSendMessage(this.content);

  @override
  List<Object?> get props => [content];
}

class TechChatClearHistory extends TechChatEvent {}

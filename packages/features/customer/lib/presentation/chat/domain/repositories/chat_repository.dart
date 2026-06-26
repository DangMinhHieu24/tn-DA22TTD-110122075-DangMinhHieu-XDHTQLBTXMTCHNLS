import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatMessage>>> getHistory();
  Future<Either<Failure, ChatMessage>> sendMessage(String content);
  Future<Either<Failure, void>> clearHistory();
}

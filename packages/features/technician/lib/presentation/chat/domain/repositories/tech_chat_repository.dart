import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../entities/tech_chat_message.dart';

abstract class TechChatRepository {
  Future<Either<Failure, List<TechChatMessage>>> getHistory();
  Future<Either<Failure, TechChatMessage>> sendMessage(String content);
  Future<Either<Failure, void>> clearHistory();
}

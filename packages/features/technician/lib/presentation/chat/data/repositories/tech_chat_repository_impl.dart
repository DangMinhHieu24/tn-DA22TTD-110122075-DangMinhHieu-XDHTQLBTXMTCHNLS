import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../../domain/entities/tech_chat_message.dart';
import '../../domain/repositories/tech_chat_repository.dart';
import '../datasources/tech_chat_remote_datasource.dart';

class TechChatRepositoryImpl implements TechChatRepository {
  final TechChatRemoteDataSource remoteDataSource;

  TechChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TechChatMessage>>> getHistory() async {
    try {
      final messages = await remoteDataSource.getHistory();
      return Right(messages);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TechChatMessage>> sendMessage(String content) async {
    try {
      final message = await remoteDataSource.sendMessage(content);
      return Right(message);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearHistory() async {
    try {
      await remoteDataSource.clearHistory();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

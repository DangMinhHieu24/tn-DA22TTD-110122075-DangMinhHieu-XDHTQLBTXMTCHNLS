import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../../domain/entities/lookup_category.dart';
import '../../domain/entities/lookup_result.dart';
import '../../domain/repositories/lookup_repository.dart';
import '../datasources/remote/lookup_remote_datasource.dart';

class LookupRepositoryImpl implements LookupRepository {
  final LookupRemoteDataSource remoteDataSource;

  LookupRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<LookupCategory>>> getLookupCategories() async {
    try {
      final categories = await remoteDataSource.getCategories();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LookupResult>>> search({
    required String categoryId,
    String? query,
  }) async {
    try {
      final results = await remoteDataSource.search(categoryId, query);
      return Right(results);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await remoteDataSource.updateUser(userId, data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

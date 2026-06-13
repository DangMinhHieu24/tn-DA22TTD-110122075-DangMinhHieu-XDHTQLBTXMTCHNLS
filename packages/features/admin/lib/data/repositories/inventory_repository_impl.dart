import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/models/inventory_model.dart';
import '../datasources/remote/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  InventoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<InventoryModel>>> getInventoryItems() async {
    try {
      final items = await remoteDataSource.getInventoryItems();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InventoryModel>> getInventoryItemById(String id) async {
    try {
      final item = await remoteDataSource.getInventoryItemById(id);
      return Right(item);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InventoryModel>> createInventoryItem(Map<String, dynamic> data) async {
    try {
      final item = await remoteDataSource.createInventoryItem(data);
      return Right(item);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InventoryModel>> updateInventoryItem(String id, Map<String, dynamic> data) async {
    try {
      final item = await remoteDataSource.updateInventoryItem(id, data);
      return Right(item);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InventoryModel>> adjustQuantity(String id, int delta) async {
    try {
      final item = await remoteDataSource.adjustQuantity(id, delta);
      return Right(item);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInventoryItem(String id) async {
    try {
      await remoteDataSource.deleteInventoryItem(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
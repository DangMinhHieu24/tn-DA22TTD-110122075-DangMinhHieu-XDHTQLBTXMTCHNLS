import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../../data/models/inventory_model.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<InventoryModel>>> getInventoryItems();
  Future<Either<Failure, InventoryModel>> getInventoryItemById(String id);
  Future<Either<Failure, InventoryModel>> createInventoryItem(Map<String, dynamic> data);
  Future<Either<Failure, InventoryModel>> updateInventoryItem(String id, Map<String, dynamic> data);
  Future<Either<Failure, InventoryModel>> adjustQuantity(String id, int delta);
  Future<Either<Failure, void>> deleteInventoryItem(String id);
}
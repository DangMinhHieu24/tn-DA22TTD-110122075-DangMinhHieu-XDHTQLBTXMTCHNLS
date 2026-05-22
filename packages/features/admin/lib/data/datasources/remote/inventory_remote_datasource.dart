import 'package:dio/dio.dart';
import '../../models/inventory_model.dart';

abstract class InventoryRemoteDataSource {
  Future<List<InventoryModel>> getInventoryItems();
  Future<InventoryModel> getInventoryItemById(String id);
  Future<InventoryModel> createInventoryItem(Map<String, dynamic> data);
  Future<InventoryModel> updateInventoryItem(String id, Map<String, dynamic> data);
  Future<InventoryModel> adjustQuantity(String id, int delta);
  Future<void> deleteInventoryItem(String id);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final Dio dio;

  InventoryRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<InventoryModel>> getInventoryItems() async {
    final response = await dio.get('/inventory');
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data.map((e) => InventoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<InventoryModel> getInventoryItemById(String id) async {
    final response = await dio.get('/inventory/$id');
    return InventoryModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<InventoryModel> createInventoryItem(Map<String, dynamic> data) async {
    final response = await dio.post('/inventory', data: data);
    return InventoryModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<InventoryModel> updateInventoryItem(String id, Map<String, dynamic> data) async {
    final response = await dio.put('/inventory/$id', data: data);
    return InventoryModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<InventoryModel> adjustQuantity(String id, int delta) async {
    final response = await dio.patch('/inventory/$id/adjust', data: {'delta': delta});
    return InventoryModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    await dio.delete('/inventory/$id');
  }
}

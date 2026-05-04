import 'package:dio/dio.dart';
import '../../models/work_item_model.dart';

abstract class WorkRemoteDataSource {
  Future<List<WorkItemModel>> getWorkItems();
  Future<WorkItemModel> getWorkItemById(String id);
  Future<WorkItemModel> updateWorkStatus(String id, String newStatus);
  Future<List<WorkItemModel>> searchWorkItems(String query);
}

class WorkRemoteDataSourceImpl implements WorkRemoteDataSource {
  final Dio dio;
  
  WorkRemoteDataSourceImpl({required this.dio});
  
  @override
  Future<List<WorkItemModel>> getWorkItems() async {
    try {
      // Call real API endpoint
      final response = await dio.get('/work-orders');
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => WorkItemModel.fromApiJson(json)).toList();
      }
      
      throw Exception('Failed to load work items');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<WorkItemModel> getWorkItemById(String id) async {
    try {
      final response = await dio.get('/work-orders/$id');
      
      if (response.data['success'] == true) {
        return WorkItemModel.fromApiJson(response.data['data']);
      }
      
      throw Exception('Failed to load work item');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<WorkItemModel> updateWorkStatus(String id, String newStatus) async {
    try {
      final response = await dio.patch(
        '/work-orders/$id/status',
        data: {'status': newStatus},
      );
      
      if (response.data['success'] == true) {
        return WorkItemModel.fromApiJson(response.data['data']);
      }
      
      throw Exception('Failed to update work status');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<WorkItemModel>> searchWorkItems(String query) async {
    try {
      // Search by calling getWorkItems and filter locally for now
      // TODO: Implement server-side search if needed
      final items = await getWorkItems();
      
      if (query.isEmpty) return items;
      
      return items.where((item) {
        final q = query.toLowerCase();
        return item.licensePlate.toLowerCase().contains(q) ||
            item.customerName.toLowerCase().contains(q) ||
            item.vehicleModel.toLowerCase().contains(q);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}

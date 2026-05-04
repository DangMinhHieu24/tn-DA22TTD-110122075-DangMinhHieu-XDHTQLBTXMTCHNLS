import 'package:dio/dio.dart';
import '../../models/work_order_model.dart';

abstract class WorkOrderRemoteDataSource {
  Future<WorkOrderModel> createWorkOrder(Map<String, dynamic> data);
  Future<List<WorkOrderModel>> getWorkOrders();
  Future<List<WorkOrderModel>> getWorkOrdersByVehicleId(String vehicleId);
}

class WorkOrderRemoteDataSourceImpl implements WorkOrderRemoteDataSource {
  final Dio dio;

  WorkOrderRemoteDataSourceImpl({required this.dio});

  @override
  Future<WorkOrderModel> createWorkOrder(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/work-orders', data: data);
      
      if (response.data['success'] == true) {
        return WorkOrderModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to create work order');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<WorkOrderModel>> getWorkOrders() async {
    try {
      final response = await dio.get('/work-orders');
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => WorkOrderModel.fromJson(json)).toList();
      }
      
      throw Exception('Failed to fetch work orders');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<WorkOrderModel>> getWorkOrdersByVehicleId(String vehicleId) async {
    try {
      final response = await dio.get('/work-orders', queryParameters: {
        'vehicleId': vehicleId,
      });
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => WorkOrderModel.fromJson(json)).toList();
      }
      
      throw Exception('Failed to fetch vehicle history');
    } catch (e) {
      rethrow;
    }
  }
}

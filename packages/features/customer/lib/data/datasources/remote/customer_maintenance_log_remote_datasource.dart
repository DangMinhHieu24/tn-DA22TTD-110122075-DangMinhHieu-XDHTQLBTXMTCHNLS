import 'package:dio/dio.dart';
import '../../models/customer_maintenance_log_model.dart';

abstract class CustomerMaintenanceLogRemoteDataSource {
  Future<List<CustomerMaintenanceLogModel>> getMaintenanceLogsByVehicle(String vehicleId);
}

class CustomerMaintenanceLogRemoteDataSourceImpl
    implements CustomerMaintenanceLogRemoteDataSource {
  final Dio dio;

  CustomerMaintenanceLogRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CustomerMaintenanceLogModel>> getMaintenanceLogsByVehicle(String vehicleId) async {
    final response = await dio.get('/vehicles/$vehicleId/maintenance-logs');

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data.map((json) => CustomerMaintenanceLogModel.fromJson(json)).toList();
    }

    throw Exception('Failed to load maintenance logs');
  }
}
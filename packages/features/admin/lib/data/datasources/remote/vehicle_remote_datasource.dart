import 'package:dio/dio.dart';
import '../../models/vehicle_model.dart';

abstract class VehicleRemoteDataSource {
  Future<VehicleModel?> getVehicleByLicensePlate(String licensePlate);
  Future<VehicleModel> createVehicle(Map<String, dynamic> data);
}

class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final Dio dio;

  VehicleRemoteDataSourceImpl({required this.dio});

  @override
  Future<VehicleModel?> getVehicleByLicensePlate(String licensePlate) async {
    try {
      final response = await dio.get('/vehicles/plate/$licensePlate');
      
      if (response.data['success'] == true) {
        return VehicleModel.fromJson(response.data['data']);
      }
      
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Vehicle not found
      }
      rethrow;
    }
  }

  @override
  Future<VehicleModel> createVehicle(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/vehicles', data: data);
      
      if (response.data['success'] == true) {
        return VehicleModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to create vehicle');
    } catch (e) {
      rethrow;
    }
  }
}

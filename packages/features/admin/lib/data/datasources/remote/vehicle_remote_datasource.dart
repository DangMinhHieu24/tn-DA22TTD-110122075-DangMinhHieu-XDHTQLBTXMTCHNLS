import 'package:dio/dio.dart';
import '../../models/vehicle_model.dart';

abstract class VehicleRemoteDataSource {
  Future<VehicleModel?> getVehicleByLicensePlate(String licensePlate);
  Future<VehicleModel?> getVehicleById(String id);
  Future<CustomerWithVehicles?> getCustomerByPhone(String phone);
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
  Future<VehicleModel?> getVehicleById(String id) async {
    try {
      final response = await dio.get('/vehicles/$id');

      if (response.data['success'] == true) {
        return VehicleModel.fromJson(response.data['data']);
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<CustomerWithVehicles?> getCustomerByPhone(String phone) async {
    try {
      final response = await dio.get('/users/by-phone', queryParameters: {'phone': phone});

      if (response.data['success'] == true) {
        return CustomerWithVehicles.fromJson(response.data['data']);
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
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

/// Model representing a customer with their list of vehicles
class CustomerWithVehicles {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final List<VehicleModel> vehicles;

  const CustomerWithVehicles({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    required this.vehicles,
  });

  factory CustomerWithVehicles.fromJson(Map<String, dynamic> json) {
    return CustomerWithVehicles(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      vehicles: (json['ownedVehicles'] as List<dynamic>?)
              ?.map((v) => VehicleModel.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

import 'package:dio/dio.dart';
import '../../models/customer_vehicle_model.dart';

abstract class CustomerVehicleRemoteDataSource {
  Future<List<CustomerVehicleModel>> getVehicles({String? ownerId});
  Future<CustomerVehicleModel> updateVehicleImage(String vehicleId, String imageUrl);
}

class CustomerVehicleRemoteDataSourceImpl implements CustomerVehicleRemoteDataSource {
  final Dio dio;

  CustomerVehicleRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CustomerVehicleModel>> getVehicles({String? ownerId}) async {
    final response = await dio.get(
      '/vehicles',
      queryParameters: ownerId != null ? {'ownerId': ownerId} : null,
    );

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data.map((json) => CustomerVehicleModel.fromJson(json)).toList();
    }

    throw Exception('Failed to load vehicles');
  }

  @override
  Future<CustomerVehicleModel> updateVehicleImage(String vehicleId, String imageUrl) async {
    final response = await dio.put(
      '/vehicles/$vehicleId',
      data: {'imageUrl': imageUrl},
    );

    if (response.data['success'] == true) {
      return CustomerVehicleModel.fromJson(response.data['data']);
    }

    throw Exception('Failed to update vehicle avatar');
  }
}

import 'package:dio/dio.dart';
import '../../models/customer_work_order_model.dart';

abstract class CustomerWorkOrderRemoteDataSource {
  Future<List<CustomerWorkOrderModel>> getWorkOrdersByVehicle(String vehicleId);
}

class CustomerWorkOrderRemoteDataSourceImpl
    implements CustomerWorkOrderRemoteDataSource {
  final Dio dio;

  CustomerWorkOrderRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CustomerWorkOrderModel>> getWorkOrdersByVehicle(String vehicleId) async {
    final response = await dio.get(
      '/work-orders',
      queryParameters: {'vehicleId': vehicleId},
    );

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data.map((json) => CustomerWorkOrderModel.fromJson(json)).toList();
    }

    throw Exception('Failed to load work orders');
  }
}

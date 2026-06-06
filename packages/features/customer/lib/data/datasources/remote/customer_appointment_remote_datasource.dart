import 'package:dio/dio.dart';
import '../../models/customer_appointment_model.dart';

abstract class CustomerAppointmentRemoteDataSource {
  Future<List<CustomerAppointmentModel>> getMyAppointments();
  Future<CustomerAppointmentModel> createAppointment(Map<String, dynamic> data);
  Future<void> cancelAppointment(String id);
}

class CustomerAppointmentRemoteDataSourceImpl
    implements CustomerAppointmentRemoteDataSource {
  final Dio dio;

  CustomerAppointmentRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CustomerAppointmentModel>> getMyAppointments() async {
    final response = await dio.get('/appointments/my');

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data
          .map((json) => CustomerAppointmentModel.fromJson(json))
          .toList();
    }

    throw Exception('Failed to load appointments');
  }

  @override
  Future<CustomerAppointmentModel> createAppointment(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/appointments', data: data);

    if (response.data['success'] == true) {
      return CustomerAppointmentModel.fromJson(response.data['data']);
    }

    throw Exception(response.data['message'] ?? 'Failed to create appointment');
  }

  @override
  Future<void> cancelAppointment(String id) async {
    final response = await dio.patch('/appointments/$id/cancel');

    if (response.data['success'] != true) {
      throw Exception(
          response.data['message'] ?? 'Failed to cancel appointment');
    }
  }
}

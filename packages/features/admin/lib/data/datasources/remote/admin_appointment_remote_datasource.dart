import 'package:dio/dio.dart';
import '../../models/admin_appointment_model.dart';

abstract class AdminAppointmentRemoteDataSource {
  Future<List<AdminAppointmentModel>> getUpcomingAppointments({String? date, String? dateFrom, String? dateTo, String? status});
  Future<void> deleteAppointment(String id);
}

class AdminAppointmentRemoteDataSourceImpl implements AdminAppointmentRemoteDataSource {
  final Dio dio;

  AdminAppointmentRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<AdminAppointmentModel>> getUpcomingAppointments({String? date, String? dateFrom, String? dateTo, String? status}) async {
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date;
    if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
    if (dateTo != null) queryParams['dateTo'] = dateTo;
    if (status != null) queryParams['status'] = status;

    final response = await dio.get(
      '/appointments',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data.map((json) => AdminAppointmentModel.fromJson(json)).toList();
    }

    throw Exception('Failed to load appointments');
  }

  @override
  Future<void> deleteAppointment(String id) async {
    final response = await dio.delete('/appointments/$id');

    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to delete appointment');
    }
  }
}

import 'package:dio/dio.dart';
import '../../models/dashboard_stats_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSourceImpl({required this.dio});

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final response = await dio.get('/work-orders/stats/dashboard');
      final data = response.data is Map && response.data['data'] != null
          ? response.data['data']
          : response.data;
      return DashboardStatsModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}

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
      final response = await dio.get('/admin/dashboard/stats');
      return DashboardStatsModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

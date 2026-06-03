import 'package:dio/dio.dart';
import '../../models/revenue_report_model.dart';

abstract class RevenueReportRemoteDataSource {
  Future<RevenueReportModel> getRevenueReport({
    required DateTime start,
    required DateTime end,
  });
}

class RevenueReportRemoteDataSourceImpl implements RevenueReportRemoteDataSource {
  final Dio dio;

  RevenueReportRemoteDataSourceImpl({required this.dio});

  @override
  Future<RevenueReportModel> getRevenueReport({
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await dio.get(
      '/work-orders/stats/revenue-report',
      queryParameters: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
    );

    return RevenueReportModel.fromJson(response.data as Map<String, dynamic>);
  }
}

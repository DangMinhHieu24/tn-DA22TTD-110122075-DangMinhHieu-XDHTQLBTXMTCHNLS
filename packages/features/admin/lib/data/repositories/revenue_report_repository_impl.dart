import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/revenue_report.dart';
import '../../domain/repositories/revenue_report_repository.dart';
import '../datasources/remote/revenue_report_remote_datasource.dart';

class RevenueReportRepositoryImpl implements RevenueReportRepository {
  final RevenueReportRemoteDataSource remoteDataSource;

  RevenueReportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, RevenueReport>> getRevenueReport({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final report = await remoteDataSource.getRevenueReport(start: start, end: end);
      return Right(report);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/revenue_report.dart';

abstract class RevenueReportRepository {
  Future<Either<Failure, RevenueReport>> getRevenueReport({
    required DateTime start,
    required DateTime end,
  });
}

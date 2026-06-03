import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/revenue_report.dart';
import '../repositories/revenue_report_repository.dart';

class GetRevenueReport {
  final RevenueReportRepository repository;

  GetRevenueReport(this.repository);

  Future<Either<Failure, RevenueReport>> call({
    required DateTime start,
    required DateTime end,
  }) {
    return repository.getRevenueReport(start: start, end: end);
  }
}

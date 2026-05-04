import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardStats {
  final DashboardRepository repository;

  GetDashboardStats(this.repository);

  Future<Either<Failure, DashboardStats>> call() {
    return repository.getDashboardStats();
  }
}

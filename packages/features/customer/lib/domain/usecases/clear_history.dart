import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../repositories/customer_repository.dart';

class ClearHistory {
  final CustomerRepository repository;

  ClearHistory(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.clearAppointmentHistory();
  }
}

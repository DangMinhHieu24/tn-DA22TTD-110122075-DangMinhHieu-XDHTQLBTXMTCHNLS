import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../repositories/customer_repository.dart';

class CancelAppointment {
  final CustomerRepository repository;

  CancelAppointment(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.cancelAppointment(id);
  }
}

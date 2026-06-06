import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/customer_appointment.dart';
import '../repositories/customer_repository.dart';

class GetMyAppointments {
  final CustomerRepository repository;

  GetMyAppointments(this.repository);

  Future<Either<Failure, List<CustomerAppointment>>> call() {
    return repository.getMyAppointments();
  }
}

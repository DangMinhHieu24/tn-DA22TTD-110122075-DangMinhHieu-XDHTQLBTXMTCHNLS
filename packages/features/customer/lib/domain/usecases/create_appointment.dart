import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/customer_appointment.dart';
import '../repositories/customer_repository.dart';

class CreateAppointment {
  final CustomerRepository repository;

  CreateAppointment(this.repository);

  Future<Either<Failure, CustomerAppointment>> call({
    required DateTime scheduledAt,
    String? serviceType,
    String? notes,
  }) {
    return repository.createAppointment(
      scheduledAt: scheduledAt,
      serviceType: serviceType,
      notes: notes,
    );
  }
}

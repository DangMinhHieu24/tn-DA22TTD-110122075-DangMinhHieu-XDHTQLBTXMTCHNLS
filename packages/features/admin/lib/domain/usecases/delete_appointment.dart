import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../repositories/admin_appointment_repository.dart';

class DeleteAppointment {
  final AdminAppointmentRepository repository;

  DeleteAppointment(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteAppointment(id);
  }
}

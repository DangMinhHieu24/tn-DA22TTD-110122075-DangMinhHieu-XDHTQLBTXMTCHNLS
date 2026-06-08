import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/admin_appointment.dart';
import '../repositories/admin_appointment_repository.dart';

class GetUpcomingAppointments {
  final AdminAppointmentRepository repository;

  GetUpcomingAppointments(this.repository);

  Future<Either<Failure, List<AdminAppointment>>> call({String? date, String? dateFrom, String? dateTo}) {
    return repository.getUpcomingAppointments(date: date, dateFrom: dateFrom, dateTo: dateTo);
  }
}

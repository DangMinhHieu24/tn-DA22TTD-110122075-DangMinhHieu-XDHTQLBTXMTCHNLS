import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/admin_appointment.dart';

abstract class AdminAppointmentRepository {
  Future<Either<Failure, List<AdminAppointment>>> getUpcomingAppointments({String? date, String? dateFrom, String? dateTo});
  Future<Either<Failure, void>> deleteAppointment(String id);
}

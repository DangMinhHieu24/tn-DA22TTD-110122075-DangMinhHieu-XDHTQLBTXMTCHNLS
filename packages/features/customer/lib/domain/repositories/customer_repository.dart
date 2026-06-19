import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/customer_vehicle.dart';
import '../entities/customer_work_order.dart';
import '../entities/customer_maintenance_log.dart';
import '../entities/customer_appointment.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<CustomerVehicle>>> getCustomerVehicles({String? ownerId});
  Future<Either<Failure, List<CustomerWorkOrder>>> getWorkOrdersByVehicle(String vehicleId);
  Future<Either<Failure, List<CustomerMaintenanceLog>>> getMaintenanceLogsByVehicle(String vehicleId);

  // Service approval
  Future<Either<Failure, void>> approveService(String workOrderId, String serviceId);
  Future<Either<Failure, void>> rejectService(String workOrderId, String serviceId);

  // Appointments
  Future<Either<Failure, List<CustomerAppointment>>> getMyAppointments();
  Future<Either<Failure, CustomerAppointment>> createAppointment({
    required DateTime scheduledAt,
    String? serviceType,
    String? notes,
    String? vehicleId,
  });
  Future<Either<Failure, void>> cancelAppointment(String id);
  Future<Either<Failure, void>> clearAppointmentHistory();
}

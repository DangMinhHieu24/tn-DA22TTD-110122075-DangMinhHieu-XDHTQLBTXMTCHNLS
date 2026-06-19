import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/customer_appointment.dart';
import '../../domain/entities/customer_maintenance_log.dart';
import '../../domain/entities/customer_vehicle.dart';
import '../../domain/entities/customer_work_order.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/remote/customer_appointment_remote_datasource.dart';
import '../datasources/remote/customer_maintenance_log_remote_datasource.dart';
import '../datasources/remote/customer_vehicle_remote_datasource.dart';
import '../datasources/remote/customer_work_order_remote_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerVehicleRemoteDataSource vehicleRemoteDataSource;
  final CustomerWorkOrderRemoteDataSource workOrderRemoteDataSource;
  final CustomerMaintenanceLogRemoteDataSource maintenanceLogRemoteDataSource;
  final CustomerAppointmentRemoteDataSource appointmentRemoteDataSource;

  CustomerRepositoryImpl({
    required this.vehicleRemoteDataSource,
    required this.workOrderRemoteDataSource,
    required this.maintenanceLogRemoteDataSource,
    required this.appointmentRemoteDataSource,
  });

  @override
  Future<Either<Failure, List<CustomerVehicle>>> getCustomerVehicles({
    String? ownerId,
  }) async {
    try {
      final vehicles = await vehicleRemoteDataSource.getVehicles(ownerId: ownerId);
      return Right(vehicles);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CustomerWorkOrder>>> getWorkOrdersByVehicle(
    String vehicleId,
  ) async {
    try {
      final workOrders = await workOrderRemoteDataSource.getWorkOrdersByVehicle(vehicleId);
      return Right(workOrders);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CustomerMaintenanceLog>>> getMaintenanceLogsByVehicle(
    String vehicleId,
  ) async {
    try {
      final maintenanceLogs = await maintenanceLogRemoteDataSource.getMaintenanceLogsByVehicle(vehicleId);
      return Right(maintenanceLogs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveService(String workOrderId, String serviceId) async {
    try {
      await workOrderRemoteDataSource.approveService(workOrderId, serviceId, 'APPROVED');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectService(String workOrderId, String serviceId) async {
    try {
      await workOrderRemoteDataSource.approveService(workOrderId, serviceId, 'REJECTED');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CustomerAppointment>>> getMyAppointments() async {
    try {
      final appointments = await appointmentRemoteDataSource.getMyAppointments();
      return Right(appointments);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerAppointment>> createAppointment({
    required DateTime scheduledAt,
    String? serviceType,
    String? notes,
    String? vehicleId,
  }) async {
    try {
      final appointment = await appointmentRemoteDataSource.createAppointment({
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        if (serviceType != null) 'serviceType': serviceType,
        if (notes != null) 'notes': notes,
        if (vehicleId != null) 'vehicleId': vehicleId,
      });
      return Right(appointment);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelAppointment(String id) async {
    try {
      await appointmentRemoteDataSource.cancelAppointment(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAppointmentHistory() async {
    try {
      await appointmentRemoteDataSource.clearAppointmentHistory();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

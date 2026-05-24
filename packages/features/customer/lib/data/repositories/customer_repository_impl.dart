import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/customer_maintenance_log.dart';
import '../../domain/entities/customer_vehicle.dart';
import '../../domain/entities/customer_work_order.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/remote/customer_maintenance_log_remote_datasource.dart';
import '../datasources/remote/customer_vehicle_remote_datasource.dart';
import '../datasources/remote/customer_work_order_remote_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerVehicleRemoteDataSource vehicleRemoteDataSource;
  final CustomerWorkOrderRemoteDataSource workOrderRemoteDataSource;
  final CustomerMaintenanceLogRemoteDataSource maintenanceLogRemoteDataSource;

  CustomerRepositoryImpl({
    required this.vehicleRemoteDataSource,
    required this.workOrderRemoteDataSource,
    required this.maintenanceLogRemoteDataSource,
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
}

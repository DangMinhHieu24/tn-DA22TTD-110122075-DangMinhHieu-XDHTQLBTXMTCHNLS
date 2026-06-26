import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/vehicle_detail.dart';
import '../entities/inventory_part.dart';
import '../entities/work_item.dart';

abstract class TechLookupRepository {
  Future<Either<Failure, VehicleDetail>> searchVehicleByPlate(String licensePlate);
  Future<Either<Failure, List<VehicleDetail>>> getAllVehicles({String? query});
  Future<Either<Failure, WarrantyResponse>> getVehicleWarranties(String vehicleId);
  Future<Either<Failure, List<InventoryPart>>> getInventoryParts({String? query});
  Future<Either<Failure, List<WorkItem>>> searchWorkOrders({String? query, String? technicianId});
}

import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../../domain/repositories/tech_lookup_repository.dart';
import '../../domain/entities/vehicle_detail.dart';
import '../../domain/entities/inventory_part.dart';
import '../../domain/entities/work_item.dart';
import '../datasources/remote/tech_lookup_remote_datasource.dart';

class TechLookupRepositoryImpl implements TechLookupRepository {
  final TechLookupRemoteDataSource remoteDataSource;

  TechLookupRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, VehicleDetail>> searchVehicleByPlate(
      String licensePlate) async {
    try {
      final result =
          await remoteDataSource.searchVehicleByPlate(licensePlate);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VehicleDetail>>> getAllVehicles(
      {String? query}) async {
    try {
      final result = await remoteDataSource.getAllVehicles(query: query);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WarrantyResponse>> getVehicleWarranties(
      String vehicleId) async {
    try {
      final result = await remoteDataSource.getVehicleWarranties(vehicleId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InventoryPart>>> getInventoryParts(
      {String? query}) async {
    try {
      final result = await remoteDataSource.getInventoryParts(query: query);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkItem>>> searchWorkOrders(
      {String? query, String? technicianId}) async {
    try {
      final result = await remoteDataSource.searchWorkOrders(
          query: query, technicianId: technicianId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

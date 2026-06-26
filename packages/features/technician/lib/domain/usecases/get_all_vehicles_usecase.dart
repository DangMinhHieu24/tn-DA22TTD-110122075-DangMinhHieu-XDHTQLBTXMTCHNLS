import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../repositories/tech_lookup_repository.dart';
import '../entities/vehicle_detail.dart';

class GetAllVehiclesUseCase
    implements UseCase<List<VehicleDetail>, GetAllVehiclesParams> {
  final TechLookupRepository repository;

  GetAllVehiclesUseCase(this.repository);

  @override
  Future<Either<Failure, List<VehicleDetail>>> call(
      GetAllVehiclesParams params) {
    return repository.getAllVehicles(query: params.query);
  }
}

class GetAllVehiclesParams {
  final String? query;
  const GetAllVehiclesParams({this.query});
}

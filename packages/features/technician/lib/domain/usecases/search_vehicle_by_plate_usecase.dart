import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../repositories/tech_lookup_repository.dart';
import '../entities/vehicle_detail.dart';

class SearchVehicleByPlateUseCase
    implements UseCase<VehicleDetail, SearchVehicleByPlateParams> {
  final TechLookupRepository repository;

  SearchVehicleByPlateUseCase(this.repository);

  @override
  Future<Either<Failure, VehicleDetail>> call(SearchVehicleByPlateParams params) {
    return repository.searchVehicleByPlate(params.licensePlate);
  }
}

class SearchVehicleByPlateParams {
  final String licensePlate;
  const SearchVehicleByPlateParams({required this.licensePlate});
}

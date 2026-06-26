import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../repositories/tech_lookup_repository.dart';

class GetVehicleWarrantiesUseCase
    implements UseCase<WarrantyResponse, GetVehicleWarrantiesParams> {
  final TechLookupRepository repository;

  GetVehicleWarrantiesUseCase(this.repository);

  @override
  Future<Either<Failure, WarrantyResponse>> call(
      GetVehicleWarrantiesParams params) {
    return repository.getVehicleWarranties(params.vehicleId);
  }
}

class GetVehicleWarrantiesParams {
  final String vehicleId;
  const GetVehicleWarrantiesParams({required this.vehicleId});
}

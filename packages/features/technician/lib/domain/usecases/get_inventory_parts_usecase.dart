import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../repositories/tech_lookup_repository.dart';
import '../entities/inventory_part.dart';

class GetInventoryPartsUseCase
    implements UseCase<List<InventoryPart>, GetInventoryPartsParams> {
  final TechLookupRepository repository;

  GetInventoryPartsUseCase(this.repository);

  @override
  Future<Either<Failure, List<InventoryPart>>> call(GetInventoryPartsParams params) {
    return repository.getInventoryParts(query: params.query);
  }
}

class GetInventoryPartsParams {
  final String? query;
  const GetInventoryPartsParams({this.query});
}

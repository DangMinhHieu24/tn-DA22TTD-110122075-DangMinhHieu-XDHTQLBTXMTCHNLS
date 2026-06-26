import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/work_item.dart';
import '../repositories/tech_lookup_repository.dart';

class SearchWorkOrdersUseCase {
  final TechLookupRepository repository;

  SearchWorkOrdersUseCase(this.repository);

  Future<Either<Failure, List<WorkItem>>> call(SearchWorkOrdersParams params) async {
    return repository.searchWorkOrders(
      query: params.query,
      technicianId: params.technicianId,
    );
  }
}

class SearchWorkOrdersParams {
  final String? query;
  final String? technicianId;

  const SearchWorkOrdersParams({this.query, this.technicianId});
}

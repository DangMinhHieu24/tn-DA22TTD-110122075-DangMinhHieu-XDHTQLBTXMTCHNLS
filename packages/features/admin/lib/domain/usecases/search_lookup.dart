import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../entities/lookup_result.dart';
import '../repositories/lookup_repository.dart';

class SearchLookupParams {
  final String categoryId;
  final String? query;

  const SearchLookupParams({
    required this.categoryId,
    this.query,
  });
}

/// Use case to perform a lookup search.
class SearchLookupUseCase implements UseCase<List<LookupResult>, SearchLookupParams> {
  final LookupRepository repository;

  SearchLookupUseCase(this.repository);

  @override
  Future<Either<Failure, List<LookupResult>>> call(SearchLookupParams params) {
    return repository.search(
      categoryId: params.categoryId,
      query: params.query,
    );
  }
}

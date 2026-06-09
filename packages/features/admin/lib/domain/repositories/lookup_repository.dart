import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../entities/lookup_category.dart';
import '../entities/lookup_result.dart';

/// Repository interface for lookup features.
abstract class LookupRepository {
  /// Gets the available lookup categories.
  Future<Either<Failure, List<LookupCategory>>> getLookupCategories();

  /// Performs a search for a specific category and query string.
  Future<Either<Failure, List<LookupResult>>> search({
    required String categoryId,
    String? query,
  });
}

import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/work_item.dart';
import '../repositories/work_repository.dart';

class SearchWorkItemsUseCase implements UseCase<List<WorkItem>, SearchWorkItemsParams> {
  final WorkRepository repository;

  const SearchWorkItemsUseCase(this.repository);

  @override
  Future<Either<Failure, List<WorkItem>>> call(SearchWorkItemsParams params) async {
    return await repository.searchWorkItems(params.query);
  }
}

class SearchWorkItemsParams extends Equatable {
  final String query;

  const SearchWorkItemsParams(this.query);

  @override
  List<Object?> get props => [query];
}

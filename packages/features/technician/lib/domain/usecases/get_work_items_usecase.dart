import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/work_item.dart';
import '../repositories/work_repository.dart';

class GetWorkItemsUseCase implements UseCase<List<WorkItem>, NoParams> {
  final WorkRepository repository;

  const GetWorkItemsUseCase(this.repository);

  @override
  Future<Either<Failure, List<WorkItem>>> call(NoParams params) async {
    return await repository.getWorkItems();
  }
}

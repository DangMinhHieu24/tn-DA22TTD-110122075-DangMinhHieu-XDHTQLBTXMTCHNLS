import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/work_item.dart';

abstract class WorkRepository {
  Future<Either<Failure, List<WorkItem>>> getWorkItems();
  Future<Either<Failure, WorkItem>> getWorkItemById(String id);
  Future<Either<Failure, WorkItem>> updateWorkStatus(
    String id,
    WorkStatus newStatus,
  );
  Future<Either<Failure, List<WorkItem>>> searchWorkItems(String query);
}

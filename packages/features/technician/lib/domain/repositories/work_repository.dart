import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/work_item.dart';
import '../entities/work_item_service.dart';

abstract class WorkRepository {
  Future<Either<Failure, List<WorkItem>>> getWorkItems({String? technicianId});
  Future<Either<Failure, WorkItem>> getWorkItemById(String id);
  Future<Either<Failure, WorkItem>> updateWorkStatus(
    String id,
    WorkStatus newStatus,
  );
  Future<Either<Failure, WorkItemService>> updateWorkServiceStatus(
    String workOrderId,
    String serviceId,
    bool isDone,
  );
  Future<Either<Failure, List<WorkItem>>> searchWorkItems(
    String query, {
    String? technicianId,
  });
  Future<Either<Failure, WorkItemService>> addService(
    String workOrderId,
    String serviceType,
    String description, {
    String? serviceName,
    double? price,
  });
  Future<Either<Failure, void>> addParts(
    String workOrderId,
    List<Map<String, dynamic>> parts,
  );
  Future<Either<Failure, void>> updateNotes(
    String workOrderId,
    String notes,
  );
}

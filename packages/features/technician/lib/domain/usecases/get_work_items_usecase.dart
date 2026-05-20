import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/work_item.dart';
import '../repositories/work_repository.dart';

class GetWorkItemsUseCase implements UseCase<List<WorkItem>, GetWorkItemsParams> {
  final WorkRepository repository;

  const GetWorkItemsUseCase(this.repository);

  @override
  Future<Either<Failure, List<WorkItem>>> call(GetWorkItemsParams params) async {
    return await repository.getWorkItems(technicianId: params.technicianId);
  }
}

class GetWorkItemsParams extends Equatable {
  final String? technicianId;

  const GetWorkItemsParams({this.technicianId});

  @override
  List<Object?> get props => [technicianId];
}

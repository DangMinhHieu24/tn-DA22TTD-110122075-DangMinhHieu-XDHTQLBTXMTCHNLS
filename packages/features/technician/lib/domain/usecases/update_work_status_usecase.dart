import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/work_item.dart';
import '../repositories/work_repository.dart';

class UpdateWorkStatusUseCase implements UseCase<WorkItem, UpdateWorkStatusParams> {
  final WorkRepository repository;

  const UpdateWorkStatusUseCase(this.repository);

  @override
  Future<Either<Failure, WorkItem>> call(UpdateWorkStatusParams params) async {
    return await repository.updateWorkStatus(params.id, params.newStatus);
  }
}

class UpdateWorkStatusParams extends Equatable {
  final String id;
  final WorkStatus newStatus;

  const UpdateWorkStatusParams({
    required this.id,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [id, newStatus];
}

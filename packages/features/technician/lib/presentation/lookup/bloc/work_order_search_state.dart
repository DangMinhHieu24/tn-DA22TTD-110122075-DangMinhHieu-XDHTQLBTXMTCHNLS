part of 'work_order_search_bloc.dart';

abstract class WorkOrderSearchState extends Equatable {
  const WorkOrderSearchState();

  @override
  List<Object?> get props => [];
}

class WorkOrderSearchInitial extends WorkOrderSearchState {
  const WorkOrderSearchInitial();
}

class WorkOrderSearchLoading extends WorkOrderSearchState {
  const WorkOrderSearchLoading();
}

class WorkOrderSearchLoaded extends WorkOrderSearchState {
  final List<WorkItem> workOrders;
  final String? query;

  const WorkOrderSearchLoaded({required this.workOrders, this.query});

  @override
  List<Object?> get props => [workOrders, query];
}

class WorkOrderSearchError extends WorkOrderSearchState {
  final String message;

  const WorkOrderSearchError({required this.message});

  @override
  List<Object?> get props => [message];
}

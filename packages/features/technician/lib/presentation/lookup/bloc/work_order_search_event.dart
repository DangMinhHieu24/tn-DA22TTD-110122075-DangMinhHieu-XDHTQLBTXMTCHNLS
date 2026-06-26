part of 'work_order_search_bloc.dart';

abstract class WorkOrderSearchEvent extends Equatable {
  const WorkOrderSearchEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkOrders extends WorkOrderSearchEvent {
  final String? query;
  final String? technicianId;
  const LoadWorkOrders({this.query, this.technicianId});

  @override
  List<Object?> get props => [query, technicianId];
}

class SearchWorkOrders extends WorkOrderSearchEvent {
  final String query;
  final String? technicianId;
  const SearchWorkOrders(this.query, {this.technicianId});

  @override
  List<Object?> get props => [query, technicianId];
}

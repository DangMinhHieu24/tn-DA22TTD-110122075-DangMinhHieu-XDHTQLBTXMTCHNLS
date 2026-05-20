import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {
  final String? technicianId;

  const LoadDashboardData({this.technicianId});

  @override
  List<Object?> get props => [technicianId];
}

class RefreshDashboardData extends DashboardEvent {
  final String? technicianId;

  const RefreshDashboardData({this.technicianId});

  @override
  List<Object?> get props => [technicianId];
}

class ResetDashboardData extends DashboardEvent {
  const ResetDashboardData();
}

class UpdateWorkStatus extends DashboardEvent {
  final String workItemId;
  final String newStatus;

  const UpdateWorkStatus({
    required this.workItemId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [workItemId, newStatus];
}

class SearchWorkItems extends DashboardEvent {
  final String query;
  final String? technicianId;

  const SearchWorkItems(this.query, {this.technicianId});

  @override
  List<Object?> get props => [query, technicianId];
}

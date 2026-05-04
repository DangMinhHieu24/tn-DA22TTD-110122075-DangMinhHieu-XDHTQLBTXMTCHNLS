import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {
  const LoadDashboardData();
}

class RefreshDashboardData extends DashboardEvent {
  const RefreshDashboardData();
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

  const SearchWorkItems(this.query);

  @override
  List<Object?> get props => [query];
}

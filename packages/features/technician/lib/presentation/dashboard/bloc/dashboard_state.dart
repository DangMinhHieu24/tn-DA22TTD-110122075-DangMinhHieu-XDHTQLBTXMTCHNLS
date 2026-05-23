import 'package:equatable/equatable.dart';
import '../../../domain/entities/work_item.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final List<WorkItem> workItems;
  final int pendingCount;
  final int inProgressCount;
  final int inspectionCount;
  final String userName;

  const DashboardLoaded({
    required this.workItems,
    required this.pendingCount,
    required this.inProgressCount,
    this.inspectionCount = 0,
    this.userName = 'Tuấn Anh',
  });

  @override
  List<Object?> get props => [
        workItems,
        pendingCount,
        inProgressCount,
        inspectionCount,
        userName,
      ];

  DashboardLoaded copyWith({
    List<WorkItem>? workItems,
    int? pendingCount,
    int? inProgressCount,
    int? inspectionCount,
    String? userName,
  }) {
    return DashboardLoaded(
      workItems: workItems ?? this.workItems,
      pendingCount: pendingCount ?? this.pendingCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      inspectionCount: inspectionCount ?? this.inspectionCount,
      userName: userName ?? this.userName,
    );
  }

  // Helper getters
  List<WorkItem> get urgentWorkItems =>
      workItems.where((item) => item.priority == WorkPriority.urgent).toList();

  List<WorkItem> get normalWorkItems =>
      workItems.where((item) => item.priority == WorkPriority.normal).toList();
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

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
  bool _isToday(String? scheduledTime, DateTime createdAt) {
    final now = DateTime.now();
    DateTime dt;
    if (scheduledTime != null) {
      dt = DateTime.tryParse(scheduledTime) ?? createdAt;
    } else {
      dt = createdAt;
    }
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  List<WorkItem> get todayWorkItems =>
      workItems
        .where((item) => item.status != WorkStatus.completed && item.status != WorkStatus.cancelled)
        .where((item) => _isToday(item.scheduledTime, item.createdAt))
        .toList();
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

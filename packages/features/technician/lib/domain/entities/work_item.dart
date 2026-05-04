import 'package:equatable/equatable.dart';

enum WorkStatus { pending, inProgress, waitingParts, completed }

enum WorkPriority { normal, urgent }

class WorkItem extends Equatable {
  final String id;
  final String licensePlate;
  final String vehicleModel;
  final String customerName;
  final String description;
  final WorkStatus status;
  final WorkPriority priority;
  final String? scheduledTime;
  final DateTime createdAt;

  const WorkItem({
    required this.id,
    required this.licensePlate,
    required this.vehicleModel,
    required this.customerName,
    required this.description,
    required this.status,
    required this.priority,
    this.scheduledTime,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        licensePlate,
        vehicleModel,
        customerName,
        description,
        status,
        priority,
        scheduledTime,
        createdAt,
      ];
}

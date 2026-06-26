import 'package:equatable/equatable.dart';
import 'work_item_service.dart';

enum WorkStatus { pending, inspection, inProgress, completed, cancelled }

class WorkItem extends Equatable {
  final String id;
  final String licensePlate;
  final String vehicleModel;
  final String? imageUrl;
  final List<String> photoUrls;
  final List<String> afterRepairPhotoUrls;
  final List<WorkItemService> services;
  final String customerName;
  final String description;
  final String? notes;
  final WorkStatus status;
  final String? scheduledTime;
  final DateTime createdAt;

  const WorkItem({
    required this.id,
    required this.licensePlate,
    required this.vehicleModel,
    this.imageUrl,
    this.photoUrls = const [],
    this.afterRepairPhotoUrls = const [],
    this.services = const [],
    required this.customerName,
    required this.description,
    this.notes,
    required this.status,
    this.scheduledTime,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        licensePlate,
        vehicleModel,
        imageUrl,
        photoUrls,
        afterRepairPhotoUrls,
        services,
        customerName,
        description,
        notes,
        status,
        scheduledTime,
        createdAt,
      ];
}

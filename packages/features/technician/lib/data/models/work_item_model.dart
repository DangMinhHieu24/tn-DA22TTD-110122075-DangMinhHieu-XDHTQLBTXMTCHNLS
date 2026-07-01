import 'package:core/core.dart';
import '../../domain/entities/work_item.dart';
import '../../domain/entities/work_item_service.dart';
import 'work_item_service_model.dart';

class WorkItemModel extends WorkItem {
  const WorkItemModel({
    required super.id,
    required super.licensePlate,
    required super.vehicleModel,
    super.imageUrl,
    super.photoUrls,
    super.afterRepairPhotoUrls,
    super.services,
    required super.customerName,
    super.customerId,
    super.customerPhone,
    required super.description,
    super.notes,
    required super.status,
    super.scheduledTime,
    required super.createdAt,
  });

  factory WorkItemModel.fromJson(Map<String, dynamic> json) {
    return WorkItemModel(
      id: json['id'] as String? ?? '',
      licensePlate: json['licensePlate'] as String? ?? '',
      vehicleModel: json['vehicleModel'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ??
          const [],
      afterRepairPhotoUrls: (json['afterRepairPhotoUrls'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ??
          const [],
      services: (json['services'] as List<dynamic>?)
          ?.map((item) => WorkItemServiceModel.fromApiJson(item as Map<String, dynamic>).toEntity())
          .toList() ??
          const [],
      customerName: json['customerName'] as String? ?? '',
      customerId: json['customerId'] as String?,
      customerPhone: json['customerPhone'] as String?,
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String?,
      status: _statusFromString(json['status'] as String? ?? ''),
      scheduledTime: json['scheduledTime'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Parse from API response (backend format)
  factory WorkItemModel.fromApiJson(Map<String, dynamic> json) {
    // Extract vehicle and customer info from nested objects
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final owner = vehicle?['owner'] as Map<String, dynamic>?;
    final services = json['services'] as List<dynamic>? ?? [];
    final photos = json['photos'] as List<dynamic>? ?? [];
    
    // Build description from services
    final description = services.isNotEmpty
        ? services.map((s) => s['description'] ?? '').join(', ')
        : json['notes'] as String? ?? 'No description';

    return WorkItemModel(
      id: json['id'] as String? ?? '',
      licensePlate: vehicle?['licensePlate'] as String? ?? 'N/A',
      vehicleModel: vehicle?['model'] as String? ?? 'Unknown',
      imageUrl: vehicle?['imageUrl'] as String?,
      photoUrls: photos
          .map((item) => (item as Map<String, dynamic>)['photoUrl'] as String?)
          .whereType<String>()
          .toList(),
      afterRepairPhotoUrls: photos
          .where((item) => (item as Map<String, dynamic>)['photoType'] == 'AFTER_REPAIR')
          .map((item) => (item as Map<String, dynamic>)['photoUrl'] as String?)
          .whereType<String>()
          .toList(),
      services: services
          .map((item) => WorkItemServiceModel.fromApiJson(item as Map<String, dynamic>).toEntity())
          .toList(),
      customerName: owner?['name'] as String? ?? 'Unknown',
      customerId: owner?['id'] as String?,
      customerPhone: owner?['phoneNumber'] as String?,
      description: description,
      notes: json['notes'] as String?,
      status: _statusFromString(json['status'] as String? ?? ''),
      scheduledTime: json['scheduledTime'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licensePlate': licensePlate,
      'vehicleModel': vehicleModel,
      'imageUrl': imageUrl,
      'photoUrls': photoUrls,
      'afterRepairPhotoUrls': afterRepairPhotoUrls,
      'services': services.map((service) => {
        'id': service.id,
        'serviceType': service.serviceType,
        'serviceName': service.serviceName,
        'description': service.description,
        'price': service.price,
        'isDone': service.isDone,
        'note': service.note,
        'createdAt': service.createdAt.toIso8601String(),
      }).toList(),
      'customerName': customerName,
      'customerId': customerId,
      'customerPhone': customerPhone,
      'description': description,
      'notes': notes,
      'status': _statusToString(status),
      'scheduledTime': scheduledTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  WorkItem toEntity() {
    return WorkItem(
      id: id,
      licensePlate: licensePlate,
      vehicleModel: vehicleModel,
      imageUrl: imageUrl,
      photoUrls: photoUrls,
      afterRepairPhotoUrls: afterRepairPhotoUrls,
      services: services,
      customerName: customerName,
      customerId: customerId,
      customerPhone: customerPhone,
      description: description,
      notes: notes,
      status: status,
      scheduledTime: scheduledTime,
      createdAt: createdAt,
    );
  }

  factory WorkItemModel.fromEntity(WorkItem entity) {
    return WorkItemModel(
      id: entity.id,
      licensePlate: entity.licensePlate,
      vehicleModel: entity.vehicleModel,
      imageUrl: entity.imageUrl,
      photoUrls: entity.photoUrls,
      afterRepairPhotoUrls: entity.afterRepairPhotoUrls,
      services: entity.services,
      customerName: entity.customerName,
      customerId: entity.customerId,
      customerPhone: entity.customerPhone,
      description: entity.description,
      notes: entity.notes,
      status: entity.status,
      scheduledTime: entity.scheduledTime,
      createdAt: entity.createdAt,
    );
  }

  WorkHistoryItem toWorkHistoryItem() {
    return WorkHistoryItem(
      orderNumber: 'WO-${id.substring(0, 8).toUpperCase()}',
      status: _statusToString(status),
      createdAt: createdAt,
      licensePlate: licensePlate,
      description: services.isNotEmpty
          ? services.map((s) => s.description ?? s.serviceName ?? 'Dịch vụ').join(', ')
          : description.isNotEmpty ? description : 'Phiếu sửa chữa',
      totalCost: services.fold<double>(0, (sum, s) => sum + (s.price ?? 0)),
    );
  }

  // Helper methods for enum conversion
  static WorkStatus _statusFromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return WorkStatus.pending;
      case 'IN_PROGRESS':
        return WorkStatus.inProgress;
      case 'WAITING_PARTS':
      case 'INSPECTION':
        return WorkStatus.inspection;
      case 'COMPLETED':
      case 'PAID':
        return WorkStatus.completed;
      case 'CANCELLED':
      case 'CANCELED':
        return WorkStatus.cancelled;
      default:
        return WorkStatus.pending;
    }
  }

  static String _statusToString(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return 'PENDING';
      case WorkStatus.inProgress:
        return 'IN_PROGRESS';
      case WorkStatus.inspection:
        return 'INSPECTION';
      case WorkStatus.completed:
        return 'COMPLETED';
      case WorkStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

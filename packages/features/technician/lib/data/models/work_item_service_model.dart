import '../../domain/entities/work_item_service.dart';

class WorkItemServiceModel extends WorkItemService {
  WorkItemServiceModel({
    required super.id,
    required super.serviceType,
    super.serviceName,
    super.description,
    super.price,
    required super.isDone,
    super.note,
    super.approvalStatus,
    required super.createdAt,
  });

  factory WorkItemServiceModel.fromApiJson(Map<String, dynamic> json) {
    return WorkItemServiceModel(
      id: json['id'] as String? ?? '',
      serviceType: json['serviceType'] as String? ?? json['service_type'] as String? ?? 'OTHER',
      serviceName: json['serviceName'] as String? ?? json['service_name'] as String?,
      description: json['description'] as String?,
      price: (json['price'] != null) ? (json['price'] as num).toDouble() : null,
      isDone: json['isDone'] as bool? ?? json['is_done'] as bool? ?? false,
      note: json['note'] as String?,
      approvalStatus: json['approvalStatus'] as String? ?? json['approval_status'] as String? ?? 'APPROVED',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'serviceType': serviceType,
      'serviceName': serviceName,
      'description': description,
      'price': price,
      'isDone': isDone,
      'note': note,
      'approvalStatus': approvalStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  WorkItemService toEntity() => this;
}

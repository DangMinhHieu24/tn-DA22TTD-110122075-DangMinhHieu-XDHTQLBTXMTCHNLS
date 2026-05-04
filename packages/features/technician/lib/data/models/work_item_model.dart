import '../../domain/entities/work_item.dart';

class WorkItemModel extends WorkItem {
  const WorkItemModel({
    required super.id,
    required super.licensePlate,
    required super.vehicleModel,
    required super.customerName,
    required super.description,
    required super.status,
    required super.priority,
    super.scheduledTime,
    required super.createdAt,
  });

  factory WorkItemModel.fromJson(Map<String, dynamic> json) {
    return WorkItemModel(
      id: json['id'] as String,
      licensePlate: json['licensePlate'] as String,
      vehicleModel: json['vehicleModel'] as String,
      customerName: json['customerName'] as String,
      description: json['description'] as String,
      status: _statusFromString(json['status'] as String),
      priority: _priorityFromString(json['priority'] as String),
      scheduledTime: json['scheduledTime'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Parse from API response (backend format)
  factory WorkItemModel.fromApiJson(Map<String, dynamic> json) {
    // Extract vehicle and customer info from nested objects
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final owner = vehicle?['owner'] as Map<String, dynamic>?;
    final services = json['services'] as List<dynamic>? ?? [];
    
    // Build description from services
    final description = services.isNotEmpty
        ? services.map((s) => s['description'] ?? '').join(', ')
        : json['notes'] ?? 'No description';

    return WorkItemModel(
      id: json['id'] as String,
      licensePlate: vehicle?['licensePlate'] as String? ?? 'N/A',
      vehicleModel: vehicle?['model'] as String? ?? 'Unknown',
      customerName: owner?['name'] as String? ?? 'Unknown',
      description: description,
      status: _statusFromString(json['status'] as String),
      priority: _priorityFromString(json['priority'] as String),
      scheduledTime: json['scheduledTime'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licensePlate': licensePlate,
      'vehicleModel': vehicleModel,
      'customerName': customerName,
      'description': description,
      'status': _statusToString(status),
      'priority': _priorityToString(priority),
      'scheduledTime': scheduledTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  WorkItem toEntity() {
    return WorkItem(
      id: id,
      licensePlate: licensePlate,
      vehicleModel: vehicleModel,
      customerName: customerName,
      description: description,
      status: status,
      priority: priority,
      scheduledTime: scheduledTime,
      createdAt: createdAt,
    );
  }

  factory WorkItemModel.fromEntity(WorkItem entity) {
    return WorkItemModel(
      id: entity.id,
      licensePlate: entity.licensePlate,
      vehicleModel: entity.vehicleModel,
      customerName: entity.customerName,
      description: entity.description,
      status: entity.status,
      priority: entity.priority,
      scheduledTime: entity.scheduledTime,
      createdAt: entity.createdAt,
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
        return WorkStatus.waitingParts;
      case 'COMPLETED':
        return WorkStatus.completed;
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
      case WorkStatus.waitingParts:
        return 'WAITING_PARTS';
      case WorkStatus.completed:
        return 'COMPLETED';
    }
  }

  static WorkPriority _priorityFromString(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return WorkPriority.urgent;
      case 'NORMAL':
        return WorkPriority.normal;
      default:
        return WorkPriority.normal;
    }
  }

  static String _priorityToString(WorkPriority priority) {
    switch (priority) {
      case WorkPriority.urgent:
        return 'URGENT';
      case WorkPriority.normal:
        return 'NORMAL';
    }
  }
}

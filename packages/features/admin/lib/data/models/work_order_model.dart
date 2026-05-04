class WorkOrderModel {
  final String id;
  final String orderNumber;
  final String vehicleId;
  final String status;
  final String priority;
  final String? notes;
  final String? technicianId;
  final double? estimatedHours;
  final String? scheduledTime;
  final List<ServiceModel> services;
  final String createdById;
  final DateTime createdAt;

  const WorkOrderModel({
    required this.id,
    required this.orderNumber,
    required this.vehicleId,
    required this.status,
    required this.priority,
    this.notes,
    this.technicianId,
    this.estimatedHours,
    this.scheduledTime,
    required this.services,
    required this.createdById,
    required this.createdAt,
  });

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    final servicesList = json['services'] as List<dynamic>? ?? [];
    
    return WorkOrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      vehicleId: json['vehicleId'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      notes: json['notes'] as String?,
      technicianId: json['technicianId'] as String?,
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
      scheduledTime: json['scheduledTime'] as String?,
      services: servicesList.map((s) => ServiceModel.fromJson(s)).toList(),
      createdById: json['createdById'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'vehicleId': vehicleId,
      'status': status,
      'priority': priority,
      'notes': notes,
      'technicianId': technicianId,
      'estimatedHours': estimatedHours,
      'scheduledTime': scheduledTime,
      'services': services.map((s) => s.toJson()).toList(),
      'createdById': createdById,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ServiceModel {
  final String serviceType;
  final String? description;

  const ServiceModel({
    required this.serviceType,
    this.description,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceType: json['serviceType'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceType': serviceType,
      'description': description,
    };
  }
}

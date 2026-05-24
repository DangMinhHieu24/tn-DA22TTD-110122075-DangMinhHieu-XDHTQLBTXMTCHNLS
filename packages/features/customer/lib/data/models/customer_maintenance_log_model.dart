import '../../domain/entities/customer_maintenance_log.dart';

class CustomerMaintenanceLogModel extends CustomerMaintenanceLog {
  const CustomerMaintenanceLogModel({
    required super.id,
    super.odometerKm,
    super.serviceType,
    super.serviceSummary,
    super.notes,
    required super.performedAt,
    super.nextServiceKm,
    super.workOrderOrderNumber,
    super.workOrderStatus,
  });

  factory CustomerMaintenanceLogModel.fromJson(Map<String, dynamic> json) {
    final workOrder = json['workOrder'] as Map<String, dynamic>?;

    return CustomerMaintenanceLogModel(
      id: json['id'] as String,
      odometerKm: json['odometerKm'] as int?,
      serviceType: json['serviceType'] as String?,
      serviceSummary: json['serviceSummary'] as String?,
      notes: json['notes'] as String?,
      performedAt: DateTime.parse(json['performedAt'] as String),
      nextServiceKm: json['nextServiceKm'] as int?,
      workOrderOrderNumber: workOrder?['orderNumber'] as String?,
      workOrderStatus: workOrder?['status'] as String?,
    );
  }
}
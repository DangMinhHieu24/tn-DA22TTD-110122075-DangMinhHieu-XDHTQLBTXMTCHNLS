import 'package:core/core.dart';

String _serviceLabel(String? type) => switch (type) {
  'MAINTENANCE' => 'Bảo dưỡng định kỳ',
  'BATTERY_CHECK' => 'Kiểm tra pin/sạc',
  'BRAKES_TIRES' => 'Phanh & Lốp',
  'OTHER_REPAIR' => 'Sửa chữa khác',
  _ => type ?? 'Dịch vụ',
};

class WorkOrderModel {
  final String id;
  final String orderNumber;
  final String vehicleId;
  final String status;
  final String? notes;
  final String? technicianId;
  final double? estimatedHours;
  final String? scheduledTime;
  final List<ServiceModel> services;
  final String createdById;
  final DateTime createdAt;
  final double? totalCost;

  const WorkOrderModel({
    required this.id,
    required this.orderNumber,
    required this.vehicleId,
    required this.status,
    this.notes,
    this.technicianId,
    this.estimatedHours,
    this.scheduledTime,
    required this.services,
    required this.createdById,
    required this.createdAt,
    this.totalCost,
  });

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    final servicesList = json['services'] as List<dynamic>? ?? [];
    
    return WorkOrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      vehicleId: json['vehicleId'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      technicianId: json['technicianId'] as String?,
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
      scheduledTime: json['scheduledTime'] as String?,
      services: servicesList.map((s) => ServiceModel.fromJson(s)).toList(),
      createdById: json['createdById'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      totalCost: (json['totalPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'vehicleId': vehicleId,
      'status': status,
      'notes': notes,
      'technicianId': technicianId,
      'estimatedHours': estimatedHours,
      'scheduledTime': scheduledTime,
      'services': services.map((s) => s.toJson()).toList(),
      'createdById': createdById,
      'createdAt': createdAt.toIso8601String(),
      'totalPrice': totalCost,
    };
  }
  WorkHistoryItem toWorkHistoryItem({String? licensePlate}) {
    return WorkHistoryItem(
      orderNumber: orderNumber,
      status: status,
      notes: notes,
      createdAt: createdAt,
      licensePlate: licensePlate,
      description: services.isNotEmpty
          ? services.map((s) => s.description ?? _serviceLabel(s.serviceType)).join(', ')
          : notes ?? 'Phiếu sửa chữa',

      totalCost: totalCost ?? services.fold<double>(0, (sum, s) => sum + (s.price ?? 0)),
    );
  }
}

class ServiceModel {
  final String serviceType;
  final String? description;
  final double? price;

  const ServiceModel({
    required this.serviceType,
    this.description,
    this.price,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceType: json['serviceType'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceType': serviceType,
      'description': description,
      'price': price,
    };
  }
}

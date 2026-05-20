import '../../domain/entities/customer_work_order.dart';

class CustomerWorkOrderModel extends CustomerWorkOrder {
  const CustomerWorkOrderModel({
    required super.id,
    required super.orderNumber,
    required super.status,
    required super.priority,
    super.notes,
    super.scheduledTime,
    required super.createdAt,
    required super.services,
  });

  factory CustomerWorkOrderModel.fromJson(Map<String, dynamic> json) {
    final servicesList = json['services'] as List<dynamic>? ?? [];

    return CustomerWorkOrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      notes: json['notes'] as String?,
      scheduledTime: json['scheduledTime'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      services: servicesList
          .map((service) => CustomerWorkOrderServiceModel.fromJson(service))
          .toList(),
    );
  }
}

class CustomerWorkOrderServiceModel extends CustomerWorkOrderService {
  const CustomerWorkOrderServiceModel({
    required super.serviceType,
    super.description,
  });

  factory CustomerWorkOrderServiceModel.fromJson(Map<String, dynamic> json) {
    return CustomerWorkOrderServiceModel(
      serviceType: json['serviceType'] as String,
      description: json['description'] as String?,
    );
  }
}

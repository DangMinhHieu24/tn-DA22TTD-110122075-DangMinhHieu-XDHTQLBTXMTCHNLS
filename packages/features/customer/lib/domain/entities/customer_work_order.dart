import 'package:equatable/equatable.dart';

class CustomerWorkOrder extends Equatable {
  final String id;
  final String orderNumber;
  final String status;
  final String priority;
  final String? notes;
  final String? scheduledTime;
  final DateTime createdAt;
  final List<CustomerWorkOrderService> services;

  const CustomerWorkOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.priority,
    this.notes,
    this.scheduledTime,
    required this.createdAt,
    required this.services,
  });

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        priority,
        notes,
        scheduledTime,
        createdAt,
        services,
      ];
}

class CustomerWorkOrderService extends Equatable {
  final String serviceType;
  final String? description;

  const CustomerWorkOrderService({
    required this.serviceType,
    this.description,
  });

  @override
  List<Object?> get props => [serviceType, description];
}

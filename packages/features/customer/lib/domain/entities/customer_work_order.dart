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
  final double? totalCost;

  const CustomerWorkOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.priority,
    this.notes,
    this.scheduledTime,
    required this.createdAt,
    required this.services,
    this.totalCost,
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
        totalCost,
      ];
}

class CustomerWorkOrderService extends Equatable {
  final String id;
  final String serviceType;
  final String? serviceName;
  final String? description;
  final double? price;
  final bool isDone;
  final String approvalStatus; // 'PENDING', 'APPROVED', 'REJECTED'

  const CustomerWorkOrderService({
    required this.id,
    required this.serviceType,
    this.serviceName,
    this.description,
    this.price,
    this.isDone = false,
    this.approvalStatus = 'APPROVED',
  });

  bool get isPending => approvalStatus == 'PENDING';
  bool get isApproved => approvalStatus == 'APPROVED';
  bool get isRejected => approvalStatus == 'REJECTED';

  @override
  List<Object?> get props => [id, serviceType, serviceName, description, price, isDone, approvalStatus];
}

import 'package:equatable/equatable.dart';

class CustomerWorkOrder extends Equatable {
  final String id;
  final String orderNumber;
  final String status;
  final String? notes;
  final String? scheduledTime;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? paidAt;
  final String? paymentMethod;
  final double? estimatedHours;
  final String? technicianName;
  final String? technicianPhone;
  final List<CustomerWorkOrderService> services;
  final List<CustomerPartsUsed> partsUsed;
  final List<CustomerWorkOrderPhoto> photos;
  final double? totalCost;

  const CustomerWorkOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.notes,
    this.scheduledTime,
    required this.createdAt,
    this.completedAt,
    this.paidAt,
    this.paymentMethod,
    this.estimatedHours,
    this.technicianName,
    this.technicianPhone,
    required this.services,
    this.partsUsed = const [],
    this.photos = const [],
    this.totalCost,
  });

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        notes,
        scheduledTime,
        createdAt,
        completedAt,
        paidAt,
        paymentMethod,
        estimatedHours,
        technicianName,
        technicianPhone,
        services,
        partsUsed,
        photos,
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

class CustomerPartsUsed extends Equatable {
  final String id;
  final String partName;
  final int quantity;
  final double unitPrice;

  const CustomerPartsUsed({
    required this.id,
    required this.partName,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;

  @override
  List<Object?> get props => [id, partName, quantity, unitPrice];
}

class CustomerWorkOrderPhoto extends Equatable {
  final String id;
  final String photoUrl;
  final String photoType; // 'INTAKE' | 'AFTER_REPAIR'
  final String? description;

  const CustomerWorkOrderPhoto({
    required this.id,
    required this.photoUrl,
    required this.photoType,
    this.description,
  });

  bool get isIntake => photoType == 'INTAKE';
  bool get isAfterRepair => photoType == 'AFTER_REPAIR';

  @override
  List<Object?> get props => [id, photoUrl, photoType, description];
}

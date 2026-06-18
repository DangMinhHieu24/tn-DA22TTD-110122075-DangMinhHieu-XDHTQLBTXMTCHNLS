import 'package:core/core.dart';
import '../../domain/entities/customer_work_order.dart';

String serviceLabel(String? type) => switch (type) {
      'MAINTENANCE' => 'Bảo dưỡng định kỳ',
      'BATTERY_CHECK' => 'Kiểm tra pin/sạc',
      'BRAKES_TIRES' => 'Phanh & Lốp',
      'OTHER_REPAIR' => 'Sửa chữa khác',
      _ => type ?? 'Dịch vụ',
    };

class CustomerWorkOrderModel extends CustomerWorkOrder {
  const CustomerWorkOrderModel({
    required super.id,
    required super.orderNumber,
    required super.status,
    super.notes,
    super.scheduledTime,
    required super.createdAt,
    super.completedAt,
    super.paidAt,
    super.paymentMethod,
    super.estimatedHours,
    super.technicianName,
    super.technicianPhone,
    required super.services,
    super.partsUsed = const [],
    super.photos = const [],
    super.totalCost,
  });

  factory CustomerWorkOrderModel.fromJson(Map<String, dynamic> json) {
    final servicesList = json['services'] as List<dynamic>? ?? [];
    final partsUsedList = json['partsUsed'] as List<dynamic>? ?? [];
    final photosList = json['photos'] as List<dynamic>? ?? [];

    // Extract technician info
    final technicianJson = json['technician'] as Map<String, dynamic>?;
    final technicianName = technicianJson?['name'] as String?;
    final technicianPhone = technicianJson?['phoneNumber'] as String?;

    return CustomerWorkOrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      scheduledTime: json['scheduledTime'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'] as String)
          : null,
      paymentMethod: json['paymentMethod'] as String?,
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
      technicianName: technicianName,
      technicianPhone: technicianPhone,
      services: servicesList
          .map((service) =>
              CustomerWorkOrderServiceModel.fromJson(service as Map<String, dynamic>))
          .toList(),
      partsUsed: partsUsedList
          .map((part) =>
              CustomerPartsUsedModel.fromJson(part as Map<String, dynamic>))
          .toList(),
      photos: photosList
          .map((photo) =>
              CustomerWorkOrderPhotoModel.fromJson(photo as Map<String, dynamic>))
          .toList(),
      totalCost: (json['totalPrice'] as num?)?.toDouble(),
    );
  }

  WorkHistoryItem toWorkHistoryItem() {
    return WorkHistoryItem(
      orderNumber: orderNumber,
      status: status,
      notes: notes,
      createdAt: createdAt,
      description: services.isNotEmpty
          ? services
              .map((s) => s.description ?? serviceLabel(s.serviceType))
              .join(', ')
          : notes ?? 'Phiếu sửa chữa',
      totalCost:
          totalCost ?? services.fold<double>(0, (sum, s) => sum + (s.price ?? 0)),
    );
  }
}

class CustomerWorkOrderServiceModel extends CustomerWorkOrderService {
  const CustomerWorkOrderServiceModel({
    required super.id,
    required super.serviceType,
    super.serviceName,
    super.description,
    super.price,
    super.isDone,
    super.approvalStatus,
  });

  factory CustomerWorkOrderServiceModel.fromJson(Map<String, dynamic> json) {
    return CustomerWorkOrderServiceModel(
      id: json['id'] as String? ?? '',
      serviceType: json['serviceType'] as String? ?? '',
      serviceName: json['serviceName'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      isDone: json['isDone'] as bool? ?? json['is_done'] as bool? ?? false,
      approvalStatus: json['approvalStatus'] as String? ??
          json['approval_status'] as String? ??
          'APPROVED',
    );
  }
}

class CustomerPartsUsedModel extends CustomerPartsUsed {
  const CustomerPartsUsedModel({
    required super.id,
    required super.partName,
    required super.quantity,
    required super.unitPrice,
  });

  factory CustomerPartsUsedModel.fromJson(Map<String, dynamic> json) {
    // partName may come from nested 'part' object
    final partJson = json['part'] as Map<String, dynamic>?;
    final partName = partJson?['partName'] as String? ??
        json['partName'] as String? ??
        'Linh kiện';
    return CustomerPartsUsedModel(
      id: json['id'] as String? ?? '',
      partName: partName,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CustomerWorkOrderPhotoModel extends CustomerWorkOrderPhoto {
  const CustomerWorkOrderPhotoModel({
    required super.id,
    required super.photoUrl,
    required super.photoType,
    super.description,
  });

  factory CustomerWorkOrderPhotoModel.fromJson(Map<String, dynamic> json) {
    return CustomerWorkOrderPhotoModel(
      id: json['id'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      photoType: json['photoType'] as String? ?? 'INTAKE',
      description: json['description'] as String?,
    );
  }
}
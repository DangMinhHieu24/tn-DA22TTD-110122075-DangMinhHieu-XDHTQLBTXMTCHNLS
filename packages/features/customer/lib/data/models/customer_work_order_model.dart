import 'package:core/core.dart';
import '../../domain/entities/customer_work_order.dart';

String _serviceLabel(String? type) => switch (type) {
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
    required super.priority,
    super.notes,
    super.scheduledTime,
    required super.createdAt,
    required super.services,
    super.totalCost,
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
          ? services.map((s) => s.description ?? _serviceLabel(s.serviceType)).join(', ')
          : notes ?? 'Phiếu sửa chữa',
      totalCost: totalCost ?? services.fold<double>(0, (sum, s) => sum + (s.price ?? 0)),
    );
  }
}

class CustomerWorkOrderServiceModel extends CustomerWorkOrderService {
  const CustomerWorkOrderServiceModel({
    required super.serviceType,
    super.description,
    super.price,
  });

  factory CustomerWorkOrderServiceModel.fromJson(Map<String, dynamic> json) {
    return CustomerWorkOrderServiceModel(
      serviceType: json['serviceType'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}

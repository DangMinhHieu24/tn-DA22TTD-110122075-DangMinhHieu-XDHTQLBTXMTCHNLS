import 'package:equatable/equatable.dart';

class VehicleDetail extends Equatable {
  final String id;
  final String licensePlate;
  final String? brand;
  final String model;
  final String? color;
  final String? imageUrl;
  final int? manufactureYear;
  final int? currentKm;
  final DateTime? warrantyExpiry;
  final String ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final List<WorkOrderSummary> recentWorkOrders;
  final DateTime createdAt;

  const VehicleDetail({
    required this.id,
    required this.licensePlate,
    this.brand,
    required this.model,
    this.color,
    this.imageUrl,
    this.manufactureYear,
    this.currentKm,
    this.warrantyExpiry,
    required this.ownerId,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    this.recentWorkOrders = const [],
    required this.createdAt,
  });

  bool get isUnderWarranty {
    if (warrantyExpiry == null) return false;
    return DateTime.now().isBefore(warrantyExpiry!);
  }

  String get displayName => '${brand ?? ''} $model'.trim();

  @override
  List<Object?> get props => [
        id, licensePlate, brand, model, color, imageUrl, manufactureYear,
        currentKm, warrantyExpiry, ownerId, ownerName, ownerPhone, ownerEmail,
        recentWorkOrders, createdAt,
      ];
}

class WorkOrderSummary extends Equatable {
  final String id;
  final String? orderNumber;
  final String status;
  final String? description;
  final DateTime createdAt;

  const WorkOrderSummary({
    required this.id,
    this.orderNumber,
    required this.status,
    this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, orderNumber, status, description, createdAt];
}

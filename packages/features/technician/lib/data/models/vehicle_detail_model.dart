import '../../domain/entities/vehicle_detail.dart';

class VehicleDetailModel extends VehicleDetail {
  const VehicleDetailModel({
    required super.id,
    required super.licensePlate,
    super.brand,
    required super.model,
    super.color,
    super.imageUrl,
    super.manufactureYear,
    super.currentKm,
    super.warrantyExpiry,
    required super.ownerId,
    super.ownerName,
    super.ownerPhone,
    super.ownerEmail,
    super.recentWorkOrders,
    required super.createdAt,
  });

  factory VehicleDetailModel.fromApiJson(Map<String, dynamic> json) {
    final vehicle = json;
    final owner = vehicle['owner'] as Map<String, dynamic>?;
    final rawOrders = vehicle['workOrders'] as List<dynamic>? ?? [];

    return VehicleDetailModel(
      id: vehicle['id'] as String? ?? '',
      licensePlate: vehicle['licensePlate'] as String? ?? '',
      brand: vehicle['brand'] as String?,
      model: vehicle['model'] as String? ?? '',
      color: vehicle['color'] as String?,
      imageUrl: vehicle['imageUrl'] as String?,
      manufactureYear: vehicle['manufactureYear'] as int?,
      currentKm: vehicle['currentKm'] as int?,
      warrantyExpiry: vehicle['warrantyExpiry'] != null
          ? DateTime.tryParse(vehicle['warrantyExpiry'] as String)
          : null,
      ownerId: vehicle['ownerId'] as String? ?? '',
      ownerName: owner?['name'] as String?,
      ownerPhone: owner?['phoneNumber'] as String?,
      ownerEmail: owner?['email'] as String?,
      recentWorkOrders: rawOrders
          .map((o) => WorkOrderSummary(
                id: o['id'] as String? ?? '',
                orderNumber: o['orderNumber'] as String?,
                status: o['status'] as String? ?? '',
                description: o['notes'] as String?,
                createdAt: DateTime.tryParse(o['createdAt'] as String? ?? '') ??
                    DateTime.now(),
              ))
          .toList(),
      createdAt: DateTime.tryParse(vehicle['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

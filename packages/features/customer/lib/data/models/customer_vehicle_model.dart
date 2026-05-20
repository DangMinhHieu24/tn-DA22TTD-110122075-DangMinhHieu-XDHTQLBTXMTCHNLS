import '../../domain/entities/customer_vehicle.dart';

class CustomerVehicleModel extends CustomerVehicle {
  const CustomerVehicleModel({
    required super.id,
    required super.licensePlate,
    super.brand,
    required super.model,
    super.imageUrl,
    super.warrantyExpiry,
    super.currentKm,
    super.color,
    super.manufactureYear,
  });

  factory CustomerVehicleModel.fromJson(Map<String, dynamic> json) {
    return CustomerVehicleModel(
      id: json['id'] as String,
      licensePlate: json['licensePlate'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String,
      imageUrl: json['imageUrl'] as String?,
      warrantyExpiry: json['warrantyExpiry'] != null
          ? DateTime.parse(json['warrantyExpiry'] as String)
          : null,
      currentKm: json['currentKm'] as int?,
      color: json['color'] as String?,
      manufactureYear: json['manufactureYear'] as int?,
    );
  }
}

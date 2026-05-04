class VehicleModel {
  final String id;
  final String licensePlate;
  final String model;
  final String? color;
  final bool warrantyStatus;
  final int? currentKm;
  final String ownerId;
  final DateTime createdAt;

  const VehicleModel({
    required this.id,
    required this.licensePlate,
    required this.model,
    this.color,
    required this.warrantyStatus,
    this.currentKm,
    required this.ownerId,
    required this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      licensePlate: json['licensePlate'] as String,
      model: json['model'] as String,
      color: json['color'] as String?,
      warrantyStatus: json['warrantyStatus'] as bool? ?? false,
      currentKm: json['currentKm'] as int?,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licensePlate': licensePlate,
      'model': model,
      'color': color,
      'warrantyStatus': warrantyStatus,
      'currentKm': currentKm,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

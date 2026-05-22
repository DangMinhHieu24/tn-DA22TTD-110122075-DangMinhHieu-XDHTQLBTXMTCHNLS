class VehicleModel {
  final String id;
  final String licensePlate;
  final String? brand;
  final String model;
  final String? color;
  final String? imageUrl;
  final int? manufactureYear;
  final String? qrCode;
  final DateTime? warrantyExpiry;
  final int? currentKm;
  final String ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final DateTime createdAt;

  const VehicleModel({
    required this.id,
    required this.licensePlate,
    this.brand,
    required this.model,
    this.color,
    this.imageUrl,
    this.manufactureYear,
    this.qrCode,
    this.warrantyExpiry,
    this.currentKm,
    required this.ownerId,
    this.ownerName,
    this.ownerPhone,
    required this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      licensePlate: json['licensePlate'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String,
      color: json['color'] as String?,
      imageUrl: json['imageUrl'] as String?,
      manufactureYear: json['manufactureYear'] as int?,
      qrCode: json['qrCode'] as String?,
      warrantyExpiry: json['warrantyExpiry'] != null 
          ? DateTime.parse(json['warrantyExpiry'] as String)
          : null,
      currentKm: json['currentKm'] as int?,
      ownerId: json['ownerId'] as String,
      ownerName: json['owner'] != null ? json['owner']['name'] as String? : null,
      ownerPhone: json['owner'] != null ? json['owner']['phoneNumber'] as String? : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licensePlate': licensePlate,
      'brand': brand,
      'model': model,
      'color': color,
      'imageUrl': imageUrl,
      'manufactureYear': manufactureYear,
      'qrCode': qrCode,
      'warrantyExpiry': warrantyExpiry?.toIso8601String(),
      'currentKm': currentKm,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  // Helper để check còn bảo hành không
  bool get isUnderWarranty {
    if (warrantyExpiry == null) return false;
    return DateTime.now().isBefore(warrantyExpiry!);
  }
}

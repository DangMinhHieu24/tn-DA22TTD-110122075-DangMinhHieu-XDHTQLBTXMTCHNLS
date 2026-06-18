import 'package:equatable/equatable.dart';

enum WarrantyStatus {
  active,
  expiringSoon,
  expired,
}

class WarrantyModel extends Equatable {
  final String id;
  final String vehicleId;
  final String warrantyType;
  final DateTime startDate;
  final DateTime expiryDate;
  final String? terms;
  final String? issuedBy;
  final int daysRemaining;
  final WarrantyStatus status;

  const WarrantyModel({
    required this.id,
    required this.vehicleId,
    required this.warrantyType,
    required this.startDate,
    required this.expiryDate,
    this.terms,
    this.issuedBy,
    required this.daysRemaining,
    required this.status,
  });

  factory WarrantyModel.fromJson(Map<String, dynamic> json) {
    return WarrantyModel(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      warrantyType: json['warrantyType'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      terms: json['terms'] as String?,
      issuedBy: json['issuedBy'] as String?,
      daysRemaining: json['daysRemaining'] as int,
      status: _statusFromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'warrantyType': warrantyType,
      'startDate': startDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'terms': terms,
      'issuedBy': issuedBy,
      'daysRemaining': daysRemaining,
      'status': _statusToString(status),
    };
  }

  static WarrantyStatus _statusFromString(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return WarrantyStatus.active;
      case 'EXPIRING_SOON':
        return WarrantyStatus.expiringSoon;
      case 'EXPIRED':
        return WarrantyStatus.expired;
      default:
        return WarrantyStatus.active;
    }
  }

  static String _statusToString(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return 'ACTIVE';
      case WarrantyStatus.expiringSoon:
        return 'EXPIRING_SOON';
      case WarrantyStatus.expired:
        return 'EXPIRED';
    }
  }

  WarrantyModel copyWith({
    String? id,
    String? vehicleId,
    String? warrantyType,
    DateTime? startDate,
    DateTime? expiryDate,
    String? terms,
    String? issuedBy,
    int? daysRemaining,
    WarrantyStatus? status,
  }) {
    return WarrantyModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      warrantyType: warrantyType ?? this.warrantyType,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      terms: terms ?? this.terms,
      issuedBy: issuedBy ?? this.issuedBy,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicleId,
        warrantyType,
        startDate,
        expiryDate,
        terms,
        issuedBy,
        daysRemaining,
        status,
      ];
}

class VehicleWarrantyInfo extends Equatable {
  final String id;
  final String licensePlate;
  final String? brand;
  final String model;
  final String? color;
  final String? imageUrl;
  final int? manufactureYear;
  final int? currentKm;

  const VehicleWarrantyInfo({
    required this.id,
    required this.licensePlate,
    this.brand,
    required this.model,
    this.color,
    this.imageUrl,
    this.manufactureYear,
    this.currentKm,
  });

  factory VehicleWarrantyInfo.fromJson(Map<String, dynamic> json) {
    return VehicleWarrantyInfo(
      id: json['id'] as String,
      licensePlate: json['licensePlate'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String,
      color: json['color'] as String?,
      imageUrl: json['imageUrl'] as String?,
      manufactureYear: json['manufactureYear'] as int?,
      currentKm: json['currentKm'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        licensePlate,
        brand,
        model,
        color,
        imageUrl,
        manufactureYear,
        currentKm,
      ];
}

class PartWarrantyModel extends Equatable {
  final String id;
  final String partId;
  final String partName;
  final String workOrderId;
  final int warrantyDays;
  final DateTime startDate;
  final DateTime expiryDate;
  final int daysRemaining;
  final WarrantyStatus status;

  const PartWarrantyModel({
    required this.id,
    required this.partId,
    required this.partName,
    required this.workOrderId,
    required this.warrantyDays,
    required this.startDate,
    required this.expiryDate,
    required this.daysRemaining,
    required this.status,
  });

  factory PartWarrantyModel.fromJson(Map<String, dynamic> json) {
    return PartWarrantyModel(
      id: json['id'] as String,
      partId: json['partId'] as String,
      partName: json['partName'] as String,
      workOrderId: json['workOrderId'] as String,
      warrantyDays: json['warrantyDays'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      daysRemaining: json['daysRemaining'] as int,
      status: _statusFromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partId': partId,
      'partName': partName,
      'workOrderId': workOrderId,
      'warrantyDays': warrantyDays,
      'startDate': startDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'daysRemaining': daysRemaining,
      'status': _statusToString(status),
    };
  }

  static WarrantyStatus _statusFromString(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return WarrantyStatus.active;
      case 'EXPIRING_SOON':
        return WarrantyStatus.expiringSoon;
      case 'EXPIRED':
        return WarrantyStatus.expired;
      default:
        return WarrantyStatus.active;
    }
  }

  static String _statusToString(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return 'ACTIVE';
      case WarrantyStatus.expiringSoon:
        return 'EXPIRING_SOON';
      case WarrantyStatus.expired:
        return 'EXPIRED';
    }
  }

  @override
  List<Object?> get props => [
        id,
        partId,
        partName,
        workOrderId,
        warrantyDays,
        startDate,
        expiryDate,
        daysRemaining,
        status,
      ];
}

class WarrantyResponse extends Equatable {
  final VehicleWarrantyInfo vehicle;
  final List<WarrantyModel> warranties;
  final List<PartWarrantyModel> partWarranties;

  const WarrantyResponse({
    required this.vehicle,
    required this.warranties,
    this.partWarranties = const [],
  });

  factory WarrantyResponse.fromJson(Map<String, dynamic> json) {
    return WarrantyResponse(
      vehicle: VehicleWarrantyInfo.fromJson(json['vehicle'] as Map<String, dynamic>),
      warranties: (json['warranties'] as List)
          .map((w) => WarrantyModel.fromJson(w as Map<String, dynamic>))
          .toList(),
      partWarranties: json['partWarranties'] != null
          ? (json['partWarranties'] as List)
              .map((pw) => PartWarrantyModel.fromJson(pw as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  @override
  List<Object?> get props => [vehicle, warranties, partWarranties];
}

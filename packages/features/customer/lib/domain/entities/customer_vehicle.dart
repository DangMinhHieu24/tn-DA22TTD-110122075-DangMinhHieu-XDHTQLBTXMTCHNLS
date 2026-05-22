import 'package:equatable/equatable.dart';

class CustomerVehicle extends Equatable {
  final String id;
  final String licensePlate;
  final String? brand;
  final String model;
  final String? imageUrl;
  final DateTime? warrantyExpiry;
  final int? currentKm;
  final String? color;
  final int? manufactureYear;

  const CustomerVehicle({
    required this.id,
    required this.licensePlate,
    this.brand,
    required this.model,
    this.imageUrl,
    this.warrantyExpiry,
    this.currentKm,
    this.color,
    this.manufactureYear,
  });

  bool get isUnderWarranty {
    if (warrantyExpiry == null) return false;
    return DateTime.now().isBefore(warrantyExpiry!);
  }

  int? get warrantyDaysRemaining {
    if (warrantyExpiry == null) return null;
    final diff = warrantyExpiry!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }

  /// Data được mã hoá vào QR: dùng vehicleId để admin quét ra là biết ngay xe nào
  String get qrData => 'VEHICLE:$id';

  @override
  List<Object?> get props => [
        id,
        licensePlate,
        brand,
        model,
        imageUrl,
        warrantyExpiry,
        currentKm,
        color,
        manufactureYear,
      ];
}

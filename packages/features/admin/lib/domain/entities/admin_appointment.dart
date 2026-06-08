import 'package:equatable/equatable.dart';

class AdminAppointment extends Equatable {
  final String id;
  final String customerName;
  final String? customerPhone;
  final String? serviceType;
  final String? notes;
  final DateTime scheduledAt;
  final String status;
  final String? vehicleLicensePlate;
  final String? vehicleModel;
  final String? vehicleBrand;

  const AdminAppointment({
    required this.id,
    required this.customerName,
    this.customerPhone,
    this.serviceType,
    this.notes,
    required this.scheduledAt,
    required this.status,
    this.vehicleLicensePlate,
    this.vehicleModel,
    this.vehicleBrand,
  });

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCancelled => status == 'CANCELLED';

  String get serviceTypeLabel {
    switch (serviceType) {
      case 'MAINTENANCE':
        return 'Bảo dưỡng định kỳ';
      case 'BATTERY_CHECK':
        return 'Kiểm tra pin/sạc';
      case 'BRAKES_TIRES':
        return 'Phanh & Lốp';
      case 'OTHER_REPAIR':
        return 'Sửa chữa khác';
      default:
        return serviceType ?? 'Chưa chọn';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [
        id,
        customerName,
        customerPhone,
        serviceType,
        notes,
        scheduledAt,
        status,
        vehicleLicensePlate,
        vehicleModel,
        vehicleBrand,
      ];
}

import 'package:equatable/equatable.dart';

class CustomerAppointment extends Equatable {
  final String id;
  final String customerId;
  final DateTime scheduledAt;
  final String? serviceType;
  final String? notes;
  final String status; // PENDING, CONFIRMED, CANCELLED

  const CustomerAppointment({
    required this.id,
    required this.customerId,
    required this.scheduledAt,
    this.serviceType,
    this.notes,
    required this.status,
  });

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCancelled => status == 'CANCELLED';
  bool get canCancel => isPending || isConfirmed;

  /// Lịch hẹn sắp tới (chưa qua và chưa hủy)
  bool get isUpcoming =>
      !isCancelled && scheduledAt.isAfter(DateTime.now());

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
        customerId,
        scheduledAt,
        serviceType,
        notes,
        status,
      ];
}

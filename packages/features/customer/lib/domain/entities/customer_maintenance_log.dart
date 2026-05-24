import 'package:equatable/equatable.dart';

class CustomerMaintenanceLog extends Equatable {
  final String id;
  final int? odometerKm;
  final String? serviceType;
  final String? serviceSummary;
  final String? notes;
  final DateTime performedAt;
  final int? nextServiceKm;
  final String? workOrderOrderNumber;
  final String? workOrderStatus;

  const CustomerMaintenanceLog({
    required this.id,
    this.odometerKm,
    this.serviceType,
    this.serviceSummary,
    this.notes,
    required this.performedAt,
    this.nextServiceKm,
    this.workOrderOrderNumber,
    this.workOrderStatus,
  });

  @override
  List<Object?> get props => [
        id,
        odometerKm,
        serviceType,
        serviceSummary,
        notes,
        performedAt,
        nextServiceKm,
        workOrderOrderNumber,
        workOrderStatus,
      ];
}
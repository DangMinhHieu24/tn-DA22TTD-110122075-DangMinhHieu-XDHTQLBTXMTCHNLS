import '../../domain/entities/admin_appointment.dart';

class AdminAppointmentModel extends AdminAppointment {
  const AdminAppointmentModel({
    required super.id,
    required super.customerName,
    super.customerPhone,
    super.serviceType,
    super.notes,
    required super.scheduledAt,
    required super.status,
    super.vehicleLicensePlate,
    super.vehicleModel,
    super.vehicleBrand,
  });

  factory AdminAppointmentModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    return AdminAppointmentModel(
      id: json['id'] as String,
      customerName: customer?['name'] as String? ?? 'Unknown',
      customerPhone: customer?['phoneNumber'] as String?,
      serviceType: json['serviceType'] as String?,
      notes: json['notes'] as String?,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      status: json['status'] as String,
      vehicleLicensePlate: vehicle?['licensePlate'] as String?,
      vehicleModel: vehicle?['model'] as String?,
      vehicleBrand: vehicle?['brand'] as String?,
    );
  }
}

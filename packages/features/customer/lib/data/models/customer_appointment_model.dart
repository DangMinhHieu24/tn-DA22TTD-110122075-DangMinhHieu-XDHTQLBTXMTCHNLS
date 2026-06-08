import '../../domain/entities/customer_appointment.dart';

class CustomerAppointmentModel extends CustomerAppointment {
  const CustomerAppointmentModel({
    required super.id,
    required super.customerId,
    required super.scheduledAt,
    super.serviceType,
    super.notes,
    required super.status,
    super.vehicleLicensePlate,
    super.vehicleBrand,
    super.vehicleModel,
  });

  factory CustomerAppointmentModel.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    return CustomerAppointmentModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      serviceType: json['serviceType'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      vehicleLicensePlate: vehicle?['licensePlate'] as String?,
      vehicleBrand: vehicle?['brand'] as String?,
      vehicleModel: vehicle?['model'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheduledAt': scheduledAt.toIso8601String(),
      if (serviceType != null) 'serviceType': serviceType,
      if (notes != null) 'notes': notes,
    };
  }
}

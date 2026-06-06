part of 'appointment_bloc.dart';

abstract class AppointmentEvent extends Equatable {
  const AppointmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadAppointments extends AppointmentEvent {}

class CreateNewAppointment extends AppointmentEvent {
  final DateTime scheduledAt;
  final String? serviceType;
  final String? notes;

  const CreateNewAppointment({
    required this.scheduledAt,
    this.serviceType,
    this.notes,
  });

  @override
  List<Object?> get props => [scheduledAt, serviceType, notes];
}

class CancelExistingAppointment extends AppointmentEvent {
  final String id;

  const CancelExistingAppointment(this.id);

  @override
  List<Object?> get props => [id];
}

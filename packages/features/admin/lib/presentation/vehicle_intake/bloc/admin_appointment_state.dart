import 'package:equatable/equatable.dart';
import '../../../domain/entities/admin_appointment.dart';

abstract class AdminAppointmentState extends Equatable {
  const AdminAppointmentState();

  @override
  List<Object?> get props => [];
}

class AdminAppointmentInitial extends AdminAppointmentState {}

class AdminAppointmentLoading extends AdminAppointmentState {}

class AdminAppointmentLoaded extends AdminAppointmentState {
  final List<AdminAppointment> appointments;

  const AdminAppointmentLoaded({required this.appointments});

  @override
  List<Object?> get props => [appointments];
}

class AdminAppointmentError extends AdminAppointmentState {
  final String message;

  const AdminAppointmentError({required this.message});

  @override
  List<Object?> get props => [message];
}


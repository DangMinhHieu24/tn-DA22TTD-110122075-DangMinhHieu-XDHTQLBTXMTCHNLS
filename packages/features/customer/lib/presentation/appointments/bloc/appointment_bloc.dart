import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/customer_appointment.dart';
import '../../../domain/usecases/get_my_appointments.dart';
import '../../../domain/usecases/create_appointment.dart';
import '../../../domain/usecases/cancel_appointment.dart';

part 'appointment_event.dart';
part 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final GetMyAppointments getMyAppointments;
  final CreateAppointment createAppointment;
  final CancelAppointment cancelAppointment;

  AppointmentBloc({
    required this.getMyAppointments,
    required this.createAppointment,
    required this.cancelAppointment,
  }) : super(AppointmentInitial()) {
    on<LoadAppointments>(_onLoadAppointments);
    on<CreateNewAppointment>(_onCreateAppointment);
    on<CancelExistingAppointment>(_onCancelAppointment);
  }

  Future<void> _onLoadAppointments(
    LoadAppointments event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    final result = await getMyAppointments();
    result.fold(
      (failure) => emit(AppointmentError(failure.message)),
      (appointments) => emit(AppointmentLoaded(appointments)),
    );
  }

  Future<void> _onCreateAppointment(
    CreateNewAppointment event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    final result = await createAppointment(
      scheduledAt: event.scheduledAt,
      serviceType: event.serviceType,
      notes: event.notes,
    );
    result.fold(
      (failure) => emit(AppointmentError(failure.message)),
      (appointment) {
        emit(AppointmentCreated(appointment));
        // Reload list after creating
        add(LoadAppointments());
      },
    );
  }

  Future<void> _onCancelAppointment(
    CancelExistingAppointment event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    final result = await cancelAppointment(event.id);
    result.fold(
      (failure) => emit(AppointmentError(failure.message)),
      (_) {
        emit(AppointmentCancelled());
        // Reload list after cancelling
        add(LoadAppointments());
      },
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/customer_appointment.dart';
import '../../../domain/usecases/get_my_appointments.dart';
import '../../../domain/usecases/create_appointment.dart';
import '../../../domain/usecases/cancel_appointment.dart';
import '../../../domain/usecases/clear_history.dart';

part 'appointment_event.dart';
part 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final GetMyAppointments getMyAppointments;
  final CreateAppointment createAppointment;
  final CancelAppointment cancelAppointment;
  final ClearHistory clearHistory;

  AppointmentBloc({
    required this.getMyAppointments,
    required this.createAppointment,
    required this.cancelAppointment,
    required this.clearHistory,
  }) : super(AppointmentInitial()) {
    on<LoadAppointments>(_onLoadAppointments);
    on<CreateNewAppointment>(_onCreateAppointment);
    on<CancelExistingAppointment>(_onCancelAppointment);
    on<ClearAppointmentHistory>(_onClearAppointmentHistory);
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
      vehicleId: event.vehicleId,
    );
    result.fold(
      (failure) => emit(AppointmentError(failure.message)),
      (appointment) {
        emit(AppointmentCreated(appointment));
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
        add(LoadAppointments());
      },
    );
  }

  Future<void> _onClearAppointmentHistory(
    ClearAppointmentHistory event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    final result = await clearHistory();
    result.fold(
      (failure) => emit(AppointmentError(failure.message)),
      (_) {
        emit(AppointmentHistoryCleared());
        add(LoadAppointments());
      },
    );
  }
}

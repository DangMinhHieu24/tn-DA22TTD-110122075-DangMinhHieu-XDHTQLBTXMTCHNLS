import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_upcoming_appointments.dart';
import 'admin_appointment_event.dart';
import 'admin_appointment_state.dart';

class AdminAppointmentBloc extends Bloc<AdminAppointmentEvent, AdminAppointmentState> {
  final GetUpcomingAppointments getUpcomingAppointments;

  AdminAppointmentBloc({required this.getUpcomingAppointments})
      : super(AdminAppointmentInitial()) {
    on<LoadUpcomingAppointments>(_onLoadUpcoming);
    on<DeleteAppointmentEvent>(_onDelete);
  }

  Future<void> _onLoadUpcoming(
    LoadUpcomingAppointments event,
    Emitter<AdminAppointmentState> emit,
  ) async {
    emit(AdminAppointmentLoading());

    final result = await getUpcomingAppointments(
      date: event.date,
      dateFrom: event.dateFrom,
      dateTo: event.dateTo,
    );

    result.fold(
      (failure) => emit(AdminAppointmentError(message: failure.message)),
      (appointments) => emit(AdminAppointmentLoaded(appointments: appointments)),
    );
  }

  void _onDelete(
    DeleteAppointmentEvent event,
    Emitter<AdminAppointmentState> emit,
  ) {
    final currentState = state;
    if (currentState is AdminAppointmentLoaded) {
      final updatedList = currentState.appointments.where((a) => a.id != event.id).toList();
      emit(AdminAppointmentLoaded(appointments: updatedList));
    }
  }
}

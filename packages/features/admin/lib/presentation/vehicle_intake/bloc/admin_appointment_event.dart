import 'package:equatable/equatable.dart';

abstract class AdminAppointmentEvent extends Equatable {
  const AdminAppointmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadUpcomingAppointments extends AdminAppointmentEvent {
  final String? date;
  final String? dateFrom;
  final String? dateTo;

  const LoadUpcomingAppointments({this.date, this.dateFrom, this.dateTo});

  @override
  List<Object?> get props => [date, dateFrom, dateTo];
}

class DeleteAppointmentEvent extends AdminAppointmentEvent {
  final String id;

  const DeleteAppointmentEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

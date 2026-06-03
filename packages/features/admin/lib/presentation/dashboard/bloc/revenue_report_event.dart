import 'package:equatable/equatable.dart';

abstract class RevenueReportEvent extends Equatable {
  const RevenueReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadRevenueReport extends RevenueReportEvent {
  final DateTime start;
  final DateTime end;

  const LoadRevenueReport({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}

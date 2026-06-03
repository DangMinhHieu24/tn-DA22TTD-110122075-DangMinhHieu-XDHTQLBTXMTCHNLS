import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_revenue_report.dart';
import 'revenue_report_event.dart';
import 'revenue_report_state.dart';

class RevenueReportBloc extends Bloc<RevenueReportEvent, RevenueReportState> {
  final GetRevenueReport getRevenueReport;

  RevenueReportBloc({required this.getRevenueReport}) : super(RevenueReportInitial()) {
    on<LoadRevenueReport>(_onLoadRevenueReport);
  }

  Future<void> _onLoadRevenueReport(
    LoadRevenueReport event,
    Emitter<RevenueReportState> emit,
  ) async {
    emit(RevenueReportLoading());
    final result = await getRevenueReport(start: event.start, end: event.end);
    result.fold(
      (failure) => emit(RevenueReportError(failure.message)),
      (report) => emit(RevenueReportLoaded(report)),
    );
  }
}

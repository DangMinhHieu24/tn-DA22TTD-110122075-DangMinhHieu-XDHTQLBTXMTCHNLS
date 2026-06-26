import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:core/core.dart';
import '../../../domain/entities/work_item.dart';
import '../../../domain/usecases/search_work_orders_usecase.dart';

part 'work_order_search_event.dart';
part 'work_order_search_state.dart';

class WorkOrderSearchBloc
    extends Bloc<WorkOrderSearchEvent, WorkOrderSearchState> {
  final SearchWorkOrdersUseCase searchWorkOrdersUseCase;

  WorkOrderSearchBloc({required this.searchWorkOrdersUseCase})
      : super(const WorkOrderSearchInitial()) {
    on<LoadWorkOrders>(_onLoad);
    on<SearchWorkOrders>(_onSearch);
  }

  Future<void> _onLoad(
    LoadWorkOrders event,
    Emitter<WorkOrderSearchState> emit,
  ) async {
    emit(const WorkOrderSearchLoading());
    final result = await searchWorkOrdersUseCase(
      SearchWorkOrdersParams(query: event.query, technicianId: event.technicianId),
    );
    result.fold(
      (failure) => emit(
        WorkOrderSearchError(message: _mapFailure(failure)),
      ),
      (orders) => emit(
        WorkOrderSearchLoaded(workOrders: orders, query: event.query),
      ),
    );
  }

  Future<void> _onSearch(
    SearchWorkOrders event,
    Emitter<WorkOrderSearchState> emit,
  ) async {
    emit(const WorkOrderSearchLoading());
    final result = await searchWorkOrdersUseCase(
      SearchWorkOrdersParams(
        query: event.query.isEmpty ? null : event.query,
        technicianId: event.technicianId,
      ),
    );
    result.fold(
      (failure) => emit(
        WorkOrderSearchError(message: _mapFailure(failure)),
      ),
      (orders) => emit(
        WorkOrderSearchLoaded(workOrders: orders, query: event.query),
      ),
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is ServerFailure) {
      return 'Không thể kết nối server. Vui lòng thử lại.';
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }
}

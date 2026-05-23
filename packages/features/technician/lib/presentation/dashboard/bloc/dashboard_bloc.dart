import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import '../../../domain/entities/work_item.dart';
import '../../../domain/usecases/get_work_items_usecase.dart';
import '../../../domain/usecases/update_work_status_usecase.dart';
import '../../../domain/usecases/search_work_items_usecase.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetWorkItemsUseCase getWorkItemsUseCase;
  final UpdateWorkStatusUseCase updateWorkStatusUseCase;
  final SearchWorkItemsUseCase searchWorkItemsUseCase;

  DashboardBloc({
    required this.getWorkItemsUseCase,
    required this.updateWorkStatusUseCase,
    required this.searchWorkItemsUseCase,
  }) : super(const DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
    on<UpdateWorkStatus>(_onUpdateWorkStatus);
    on<SearchWorkItems>(_onSearchWorkItems);
    on<ResetDashboardData>(_onResetDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    final result = await getWorkItemsUseCase(
      GetWorkItemsParams(technicianId: event.technicianId),
    );

    result.fold(
      (failure) => emit(DashboardError(_mapFailureToMessage(failure))),
      (workItems) {
        final stats = _calculateStats(workItems);
        emit(DashboardLoaded(
          workItems: workItems,
          pendingCount: stats['pending']!,
          inProgressCount: stats['inProgress']!,
          inspectionCount: stats['inspection']!,
        ));
      },
    );
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final result = await getWorkItemsUseCase(
        GetWorkItemsParams(technicianId: event.technicianId),
      );

      result.fold(
        (failure) => emit(DashboardError(_mapFailureToMessage(failure))),
        (workItems) {
          final stats = _calculateStats(workItems);
          emit(DashboardLoaded(
            workItems: workItems,
            pendingCount: stats['pending']!,
            inProgressCount: stats['inProgress']!,
            inspectionCount: stats['inspection']!,
          ));
        },
      );
    }
  }

  Future<void> _onUpdateWorkStatus(
    UpdateWorkStatus event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      final newStatus = _parseWorkStatus(event.newStatus);
      final result = await updateWorkStatusUseCase(
        UpdateWorkStatusParams(
          id: event.workItemId,
          newStatus: newStatus,
        ),
      );

      result.fold(
        (failure) {
          emit(currentState);
        },
        (updatedItem) {
          final updatedItems = currentState.workItems.map((item) {
            if (item.id == event.workItemId) {
              return updatedItem;
            }
            return item;
          }).toList();

          final stats = _calculateStats(updatedItems);

          emit(currentState.copyWith(
            workItems: updatedItems,
            pendingCount: stats['pending'],
            inProgressCount: stats['inProgress'],
            inspectionCount: stats['inspection'],
          ));
        },
      );
    }
  }

  Future<void> _onSearchWorkItems(
    SearchWorkItems event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final result = await searchWorkItemsUseCase(
        SearchWorkItemsParams(
          event.query,
          technicianId: event.technicianId,
        ),
      );

      result.fold(
        (failure) => emit(DashboardError(_mapFailureToMessage(failure))),
        (workItems) {
          final stats = _calculateStats(workItems);
          final currentState = state as DashboardLoaded;
          
          emit(currentState.copyWith(
            workItems: workItems,
            pendingCount: stats['pending'],
            inProgressCount: stats['inProgress'],
            inspectionCount: stats['inspection'],
          ));
        },
      );
    }
  }

  void _onResetDashboardData(
    ResetDashboardData event,
    Emitter<DashboardState> emit,
  ) {
    emit(const DashboardInitial());
  }

  // Helper methods
  Map<String, int> _calculateStats(List<WorkItem> items) {
    return {
      'pending': items.where((i) => i.status == WorkStatus.pending).length,
      'inProgress': items.where((i) => i.status == WorkStatus.inProgress).length,
      'inspection': items.where((i) => i.status == WorkStatus.inspection).length,
    };
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Lỗi kết nối server. Vui lòng thử lại.';
    } else if (failure is CacheFailure) {
      return 'Không có dữ liệu offline. Vui lòng kết nối mạng.';
    } else {
      return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  WorkStatus _parseWorkStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return WorkStatus.pending;
      case 'in_progress':
      case 'inprogress':
        return WorkStatus.inProgress;
      case 'waiting_parts':
      case 'waitingparts':
      case 'inspection':
      case 'inspecting':
        return WorkStatus.inspection;
      case 'completed':
        return WorkStatus.completed;
      default:
        return WorkStatus.pending;
    }
  }
}

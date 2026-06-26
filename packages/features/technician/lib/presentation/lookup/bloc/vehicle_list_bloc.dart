import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'vehicle_list_event.dart';
import 'vehicle_list_state.dart';
import '../../../domain/usecases/get_all_vehicles_usecase.dart';

class VehicleListBloc extends Bloc<VehicleListEvent, VehicleListState> {
  final GetAllVehiclesUseCase getAllVehiclesUseCase;

  VehicleListBloc({required this.getAllVehiclesUseCase})
      : super(const VehicleListInitial()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<SearchVehicles>(_onSearchVehicles);
  }

  Future<void> _onLoadVehicles(
    LoadVehicles event,
    Emitter<VehicleListState> emit,
  ) async {
    emit(const VehicleListLoading());

    final result = await getAllVehiclesUseCase(
      GetAllVehiclesParams(query: event.query),
    );

    result.fold(
      (failure) {
        emit(VehicleListError(message: _mapFailureToMessage(failure)));
      },
      (vehicles) {
        emit(VehicleListLoaded(vehicles: vehicles, query: event.query));
      },
    );
  }

  Future<void> _onSearchVehicles(
    SearchVehicles event,
    Emitter<VehicleListState> emit,
  ) async {
    emit(const VehicleListLoading());

    final result = await getAllVehiclesUseCase(
      GetAllVehiclesParams(query: event.query.isEmpty ? null : event.query),
    );

    result.fold(
      (failure) {
        emit(VehicleListError(message: _mapFailureToMessage(failure)));
      },
      (vehicles) {
        emit(VehicleListLoaded(vehicles: vehicles, query: event.query));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Không thể kết nối server. Vui lòng thử lại.';
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'vehicle_detail_event.dart';
import 'vehicle_detail_state.dart';
import '../../../domain/entities/vehicle_detail.dart';
import '../../../domain/usecases/search_vehicle_by_plate_usecase.dart';
import '../../../domain/usecases/get_vehicle_warranties_usecase.dart';

class VehicleDetailBloc
    extends Bloc<VehicleDetailEvent, VehicleDetailState> {
  final SearchVehicleByPlateUseCase searchVehicleByPlateUseCase;
  final GetVehicleWarrantiesUseCase getVehicleWarrantiesUseCase;

  VehicleDetailBloc({
    required this.searchVehicleByPlateUseCase,
    required this.getVehicleWarrantiesUseCase,
  }) : super(const VehicleDetailInitial()) {
    on<SearchVehicleByPlate>(_onSearchVehicleByPlate);
    on<SearchVehicleWarranty>(_onSearchVehicleWarranty);
    on<ClearVehicleResult>(_onClearVehicleResult);
  }

  Future<void> _onSearchVehicleByPlate(
    SearchVehicleByPlate event,
    Emitter<VehicleDetailState> emit,
  ) async {
    emit(const VehicleDetailLoading());

    final result = await searchVehicleByPlateUseCase(
      SearchVehicleByPlateParams(licensePlate: event.licensePlate),
    );

    result.fold(
      (failure) {
        emit(VehicleDetailError(message: _mapFailureToMessage(failure)));
      },
      (vehicle) {
        emit(VehicleDetailLoaded(vehicle: vehicle));
      },
    );
  }

  Future<void> _onSearchVehicleWarranty(
    SearchVehicleWarranty event,
    Emitter<VehicleDetailState> emit,
  ) async {
    emit(const VehicleDetailLoading());

    final vehicleResult = await searchVehicleByPlateUseCase(
      SearchVehicleByPlateParams(licensePlate: event.licensePlate),
    );

    if (vehicleResult.isLeft()) {
      emit(const VehicleDetailNotFound(message: 'Không tìm thấy xe'));
      return;
    }

    final vehicle = vehicleResult.getOrElse(
      () => throw StateError('unreachable'),
    );

    final warrantyResult = await getVehicleWarrantiesUseCase(
      GetVehicleWarrantiesParams(vehicleId: vehicle.id),
    );

    warrantyResult.fold(
      (wFailure) {
        emit(VehicleWarrantyLoaded(
          vehicle: vehicle,
          warranty: WarrantyResponse(
            vehicle: VehicleWarrantyInfo(
              id: vehicle.id,
              licensePlate: vehicle.licensePlate,
              brand: vehicle.brand,
              model: vehicle.model,
              color: vehicle.color,
              imageUrl: vehicle.imageUrl,
              manufactureYear: vehicle.manufactureYear,
              currentKm: vehicle.currentKm,
            ),
            warranties: const [],
            partWarranties: const [],
          ),
        ));
      },
      (warranty) {
        emit(VehicleWarrantyLoaded(vehicle: vehicle, warranty: warranty));
      },
    );
  }

  void _onClearVehicleResult(
    ClearVehicleResult event,
    Emitter<VehicleDetailState> emit,
  ) {
    emit(const VehicleDetailInitial());
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Không thể kết nối server. Vui lòng thử lại.';
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }
}

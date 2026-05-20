import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/customer_vehicle.dart';
import '../../../domain/usecases/get_customer_vehicles.dart';

part 'customer_vehicle_event.dart';
part 'customer_vehicle_state.dart';

class CustomerVehicleBloc extends Bloc<CustomerVehicleEvent, CustomerVehicleState> {
  final GetCustomerVehicles getCustomerVehicles;

  CustomerVehicleBloc({required this.getCustomerVehicles})
      : super(CustomerVehicleInitial()) {
    on<LoadCustomerVehicles>(_onLoadCustomerVehicles);
  }

  Future<void> _onLoadCustomerVehicles(
    LoadCustomerVehicles event,
    Emitter<CustomerVehicleState> emit,
  ) async {
    emit(CustomerVehicleLoading());
    final result = await getCustomerVehicles(ownerId: event.ownerId);
    result.fold(
      (failure) => emit(CustomerVehicleError(failure.message)),
      (vehicles) => emit(CustomerVehicleLoaded(vehicles)),
    );
  }
}

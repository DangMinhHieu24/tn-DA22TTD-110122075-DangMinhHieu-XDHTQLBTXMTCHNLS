import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/customer_work_order.dart';
import '../../../domain/usecases/get_vehicle_work_orders.dart';

part 'customer_work_order_event.dart';
part 'customer_work_order_state.dart';

class CustomerWorkOrderBloc
    extends Bloc<CustomerWorkOrderEvent, CustomerWorkOrderState> {
  final GetVehicleWorkOrders getVehicleWorkOrders;

  CustomerWorkOrderBloc({required this.getVehicleWorkOrders})
      : super(CustomerWorkOrderInitial()) {
    on<LoadWorkOrdersForVehicle>(_onLoadWorkOrdersForVehicle);
  }

  Future<void> _onLoadWorkOrdersForVehicle(
    LoadWorkOrdersForVehicle event,
    Emitter<CustomerWorkOrderState> emit,
  ) async {
    emit(CustomerWorkOrderLoading());
    final result = await getVehicleWorkOrders(event.vehicleId);
    result.fold(
      (failure) => emit(CustomerWorkOrderError(failure.message)),
      (workOrders) => emit(CustomerWorkOrderLoaded(workOrders)),
    );
  }
}

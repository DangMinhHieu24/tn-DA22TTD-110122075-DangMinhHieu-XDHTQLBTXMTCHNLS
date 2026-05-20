part of 'customer_work_order_bloc.dart';

abstract class CustomerWorkOrderEvent extends Equatable {
  const CustomerWorkOrderEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkOrdersForVehicle extends CustomerWorkOrderEvent {
  final String vehicleId;

  const LoadWorkOrdersForVehicle(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

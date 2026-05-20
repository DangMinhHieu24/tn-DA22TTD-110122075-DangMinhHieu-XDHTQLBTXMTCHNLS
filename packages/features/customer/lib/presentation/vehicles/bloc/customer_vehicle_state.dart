part of 'customer_vehicle_bloc.dart';

abstract class CustomerVehicleState extends Equatable {
  const CustomerVehicleState();

  @override
  List<Object?> get props => [];
}

class CustomerVehicleInitial extends CustomerVehicleState {}

class CustomerVehicleLoading extends CustomerVehicleState {}

class CustomerVehicleLoaded extends CustomerVehicleState {
  final List<CustomerVehicle> vehicles;

  const CustomerVehicleLoaded(this.vehicles);

  @override
  List<Object?> get props => [vehicles];
}

class CustomerVehicleError extends CustomerVehicleState {
  final String message;

  const CustomerVehicleError(this.message);

  @override
  List<Object?> get props => [message];
}

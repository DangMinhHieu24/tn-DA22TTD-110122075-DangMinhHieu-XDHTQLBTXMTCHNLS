part of 'customer_vehicle_bloc.dart';

abstract class CustomerVehicleEvent extends Equatable {
  const CustomerVehicleEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomerVehicles extends CustomerVehicleEvent {
  final String? ownerId;

  const LoadCustomerVehicles({this.ownerId});

  @override
  List<Object?> get props => [ownerId];
}

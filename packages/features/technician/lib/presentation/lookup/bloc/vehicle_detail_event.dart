import 'package:equatable/equatable.dart';

abstract class VehicleDetailEvent extends Equatable {
  const VehicleDetailEvent();

  @override
  List<Object?> get props => [];
}

class SearchVehicleByPlate extends VehicleDetailEvent {
  final String licensePlate;

  const SearchVehicleByPlate({required this.licensePlate});

  @override
  List<Object?> get props => [licensePlate];
}

class SearchVehicleWarranty extends VehicleDetailEvent {
  final String licensePlate;

  const SearchVehicleWarranty({required this.licensePlate});

  @override
  List<Object?> get props => [licensePlate];
}

class ClearVehicleResult extends VehicleDetailEvent {
  const ClearVehicleResult();
}

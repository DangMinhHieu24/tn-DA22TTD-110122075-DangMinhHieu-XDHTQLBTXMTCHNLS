import 'package:equatable/equatable.dart';

abstract class VehicleListEvent extends Equatable {
  const VehicleListEvent();

  @override
  List<Object?> get props => [];
}

class LoadVehicles extends VehicleListEvent {
  final String? query;

  const LoadVehicles({this.query});

  @override
  List<Object?> get props => [query];
}

class SearchVehicles extends VehicleListEvent {
  final String query;

  const SearchVehicles({required this.query});

  @override
  List<Object?> get props => [query];
}

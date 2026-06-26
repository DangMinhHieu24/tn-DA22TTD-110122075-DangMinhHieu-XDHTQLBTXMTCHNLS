import 'package:equatable/equatable.dart';
import '../../../domain/entities/vehicle_detail.dart';

abstract class VehicleListState extends Equatable {
  const VehicleListState();

  @override
  List<Object?> get props => [];
}

class VehicleListInitial extends VehicleListState {
  const VehicleListInitial();
}

class VehicleListLoading extends VehicleListState {
  const VehicleListLoading();
}

class VehicleListLoaded extends VehicleListState {
  final List<VehicleDetail> vehicles;
  final String? query;

  const VehicleListLoaded({required this.vehicles, this.query});

  @override
  List<Object?> get props => [vehicles, query];
}

class VehicleListError extends VehicleListState {
  final String message;

  const VehicleListError({required this.message});

  @override
  List<Object?> get props => [message];
}

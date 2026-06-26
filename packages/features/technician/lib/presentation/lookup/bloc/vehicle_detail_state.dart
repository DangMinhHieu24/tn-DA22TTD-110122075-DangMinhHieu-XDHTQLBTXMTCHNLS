import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/vehicle_detail.dart';

abstract class VehicleDetailState extends Equatable {
  const VehicleDetailState();

  @override
  List<Object?> get props => [];
}

class VehicleDetailInitial extends VehicleDetailState {
  const VehicleDetailInitial();
}

class VehicleDetailLoading extends VehicleDetailState {
  const VehicleDetailLoading();
}

class VehicleDetailLoaded extends VehicleDetailState {
  final VehicleDetail vehicle;

  const VehicleDetailLoaded({required this.vehicle});

  @override
  List<Object?> get props => [vehicle];
}

class VehicleWarrantyLoaded extends VehicleDetailState {
  final VehicleDetail vehicle;
  final WarrantyResponse warranty;

  const VehicleWarrantyLoaded({
    required this.vehicle,
    required this.warranty,
  });

  @override
  List<Object?> get props => [vehicle, warranty];
}

class VehicleDetailNotFound extends VehicleDetailState {
  final String message;

  const VehicleDetailNotFound({this.message = 'Không tìm thấy xe'});

  @override
  List<Object?> get props => [message];
}

class VehicleDetailError extends VehicleDetailState {
  final String message;

  const VehicleDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}

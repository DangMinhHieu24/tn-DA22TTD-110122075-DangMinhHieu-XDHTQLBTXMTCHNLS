part of 'vehicle_intake_bloc.dart';

abstract class VehicleIntakeEvent extends Equatable {
  const VehicleIntakeEvent();

  @override
  List<Object?> get props => [];
}

class VehicleIntakeLicensePlateChanged extends VehicleIntakeEvent {
  final String licensePlate;

  const VehicleIntakeLicensePlateChanged(this.licensePlate);

  @override
  List<Object?> get props => [licensePlate];
}

class VehicleIntakeLicensePlateSearched extends VehicleIntakeEvent {
  final String licensePlate;

  const VehicleIntakeLicensePlateSearched(this.licensePlate);

  @override
  List<Object?> get props => [licensePlate];
}

class VehicleIntakeQRScanned extends VehicleIntakeEvent {
  const VehicleIntakeQRScanned();
}

class VehicleIntakeOwnerNameChanged extends VehicleIntakeEvent {
  final String ownerName;

  const VehicleIntakeOwnerNameChanged(this.ownerName);

  @override
  List<Object?> get props => [ownerName];
}

class VehicleIntakeOwnerPhoneChanged extends VehicleIntakeEvent {
  final String ownerPhone;

  const VehicleIntakeOwnerPhoneChanged(this.ownerPhone);

  @override
  List<Object?> get props => [ownerPhone];
}

class VehicleIntakeVehicleTypeChanged extends VehicleIntakeEvent {
  final String vehicleType;

  const VehicleIntakeVehicleTypeChanged(this.vehicleType);

  @override
  List<Object?> get props => [vehicleType];
}

class VehicleIntakeVehicleYearChanged extends VehicleIntakeEvent {
  final String vehicleYear;

  const VehicleIntakeVehicleYearChanged(this.vehicleYear);

  @override
  List<Object?> get props => [vehicleYear];
}

class VehicleIntakeVehicleColorChanged extends VehicleIntakeEvent {
  final String vehicleColor;

  const VehicleIntakeVehicleColorChanged(this.vehicleColor);

  @override
  List<Object?> get props => [vehicleColor];
}

class VehicleIntakeHistoryRequested extends VehicleIntakeEvent {
  final String vehicleId;

  const VehicleIntakeHistoryRequested(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class VehicleIntakeTechniciansRequested extends VehicleIntakeEvent {
  const VehicleIntakeTechniciansRequested();
}

class VehicleIntakeKmChanged extends VehicleIntakeEvent {
  final String km;

  const VehicleIntakeKmChanged(this.km);

  @override
  List<Object?> get props => [km];
}

class VehicleIntakeServiceToggled extends VehicleIntakeEvent {
  final String serviceType;
  final bool isChecked;

  const VehicleIntakeServiceToggled(this.serviceType, this.isChecked);

  @override
  List<Object?> get props => [serviceType, isChecked];
}

class VehicleIntakeNotesChanged extends VehicleIntakeEvent {
  final String notes;

  const VehicleIntakeNotesChanged(this.notes);

  @override
  List<Object?> get props => [notes];
}

class VehicleIntakeTechnicianChanged extends VehicleIntakeEvent {
  final String technicianId;

  const VehicleIntakeTechnicianChanged(this.technicianId);

  @override
  List<Object?> get props => [technicianId];
}

class VehicleIntakeEstimatedHoursChanged extends VehicleIntakeEvent {
  final String hours;

  const VehicleIntakeEstimatedHoursChanged(this.hours);

  @override
  List<Object?> get props => [hours];
}

class VehicleIntakePhotoAdded extends VehicleIntakeEvent {
  final File photoFile;

  const VehicleIntakePhotoAdded(this.photoFile);

  @override
  List<Object?> get props => [photoFile];
}

class VehicleIntakePhotoCaptured extends VehicleIntakeEvent {
  const VehicleIntakePhotoCaptured();
}

class VehicleIntakePhotoPickedFromGallery extends VehicleIntakeEvent {
  const VehicleIntakePhotoPickedFromGallery();
}

class VehicleIntakePhotoRemoved extends VehicleIntakeEvent {
  final int index;

  const VehicleIntakePhotoRemoved(this.index);

  @override
  List<Object?> get props => [index];
}

class VehicleIntakeSubmitted extends VehicleIntakeEvent {
  const VehicleIntakeSubmitted();

  @override
  List<Object?> get props => [];
}

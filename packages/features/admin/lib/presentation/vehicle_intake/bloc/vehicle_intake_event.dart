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
}

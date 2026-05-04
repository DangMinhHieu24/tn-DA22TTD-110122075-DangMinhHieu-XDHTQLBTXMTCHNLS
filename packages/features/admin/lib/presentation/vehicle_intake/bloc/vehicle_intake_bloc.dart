import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import '../../../data/repositories/vehicle_intake_repository.dart';

part 'vehicle_intake_event.dart';
part 'vehicle_intake_state.dart';

class VehicleIntakeBloc extends Bloc<VehicleIntakeEvent, VehicleIntakeState> {
  final VehicleIntakeRepository repository;
  final ImageUploadService imageUploadService;

  VehicleIntakeBloc({
    required this.repository,
    required this.imageUploadService,
  }) : super(const VehicleIntakeState()) {
    on<VehicleIntakeLicensePlateChanged>(_onLicensePlateChanged);
    on<VehicleIntakeKmChanged>(_onKmChanged);
    on<VehicleIntakeServiceToggled>(_onServiceToggled);
    on<VehicleIntakeNotesChanged>(_onNotesChanged);
    on<VehicleIntakeTechnicianChanged>(_onTechnicianChanged);
    on<VehicleIntakeEstimatedHoursChanged>(_onEstimatedHoursChanged);
    on<VehicleIntakePhotoAdded>(_onPhotoAdded);
    on<VehicleIntakePhotoCaptured>(_onPhotoCaptured);
    on<VehicleIntakePhotoPickedFromGallery>(_onPhotoPickedFromGallery);
    on<VehicleIntakePhotoRemoved>(_onPhotoRemoved);
    on<VehicleIntakeSubmitted>(_onSubmitted);
    on<VehicleIntakeLicensePlateSearched>(_onLicensePlateSearched);
  }

  void _onLicensePlateChanged(
    VehicleIntakeLicensePlateChanged event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(
      licensePlate: event.licensePlate,
      vehicleId: null,
      vehicleFound: false,
      vehicleModel: null,
      vehicleColor: null,
      warrantyStatus: null,
    ));
  }

  void _onKmChanged(
    VehicleIntakeKmChanged event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(km: event.km));
  }

  void _onServiceToggled(
    VehicleIntakeServiceToggled event,
    Emitter<VehicleIntakeState> emit,
  ) {
    switch (event.serviceType) {
      case 'maintenance':
        emit(state.copyWith(maintenanceChecked: event.isChecked));
        break;
      case 'battery':
        emit(state.copyWith(batteryChecked: event.isChecked));
        break;
      case 'brakes':
        emit(state.copyWith(brakesChecked: event.isChecked));
        break;
      case 'other':
        emit(state.copyWith(otherChecked: event.isChecked));
        break;
    }
  }

  void _onNotesChanged(
    VehicleIntakeNotesChanged event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(notes: event.notes));
  }

  void _onTechnicianChanged(
    VehicleIntakeTechnicianChanged event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(selectedTechnician: event.technicianId));
  }

  void _onEstimatedHoursChanged(
    VehicleIntakeEstimatedHoursChanged event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(estimatedHours: event.hours));
  }

  void _onPhotoAdded(
    VehicleIntakePhotoAdded event,
    Emitter<VehicleIntakeState> emit,
  ) {
    final updatedPhotos = List<File>.from(state.photoFiles)..add(event.photoFile);
    emit(state.copyWith(photoFiles: updatedPhotos));
  }

  Future<void> _onPhotoCaptured(
    VehicleIntakePhotoCaptured event,
    Emitter<VehicleIntakeState> emit,
  ) async {
    try {
      final File? photo = await imageUploadService.takePhoto();
      if (photo != null) {
        final updatedPhotos = List<File>.from(state.photoFiles)..add(photo);
        emit(state.copyWith(photoFiles: updatedPhotos));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể chụp ảnh: ${e.toString()}'));
    }
  }

  Future<void> _onPhotoPickedFromGallery(
    VehicleIntakePhotoPickedFromGallery event,
    Emitter<VehicleIntakeState> emit,
  ) async {
    try {
      final File? photo = await imageUploadService.pickImage();
      if (photo != null) {
        final updatedPhotos = List<File>.from(state.photoFiles)..add(photo);
        emit(state.copyWith(photoFiles: updatedPhotos));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể chọn ảnh: ${e.toString()}'));
    }
  }

  void _onPhotoRemoved(
    VehicleIntakePhotoRemoved event,
    Emitter<VehicleIntakeState> emit,
  ) {
    final updatedPhotos = List<File>.from(state.photoFiles)..removeAt(event.index);
    emit(state.copyWith(photoFiles: updatedPhotos));
  }

  Future<void> _onLicensePlateSearched(
    VehicleIntakeLicensePlateSearched event,
    Emitter<VehicleIntakeState> emit,
  ) async {
    try {
      emit(state.copyWith(isSearching: true));
      
      final vehicle = await repository.searchVehicle(event.licensePlate);
      
      if (vehicle != null) {
        emit(state.copyWith(
          isSearching: false,
          vehicleId: vehicle.id,
          vehicleFound: true,
          vehicleModel: vehicle.model,
          vehicleColor: vehicle.color,
          warrantyStatus: vehicle.warrantyStatus,
        ));
      } else {
        emit(state.copyWith(
          isSearching: false,
          vehicleFound: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isSearching: false,
        vehicleFound: false,
        errorMessage: 'Không thể tìm kiếm xe: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSubmitted(
    VehicleIntakeSubmitted event,
    Emitter<VehicleIntakeState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      // Validate
      late String resolvedVehicleId;
      if (state.vehicleId == null) {
        final plate = state.licensePlate.trim();
        if (plate.isEmpty) {
          throw Exception('Vui lòng nhập biển số xe');
        }

        final vehicle = await repository.searchVehicle(plate);
        if (vehicle == null) {
          throw Exception('Không tìm thấy xe với biển số đã nhập');
        }

        resolvedVehicleId = vehicle.id;
        emit(state.copyWith(
          vehicleId: resolvedVehicleId,
          vehicleFound: true,
          vehicleModel: vehicle.model,
          vehicleColor: vehicle.color,
          warrantyStatus: vehicle.warrantyStatus,
        ));
      } else {
        resolvedVehicleId = state.vehicleId!;
      }

      // Collect selected services
      final services = <String>[];
      if (state.maintenanceChecked) services.add('maintenance');
      if (state.batteryChecked) services.add('battery');
      if (state.brakesChecked) services.add('brakes');
      if (state.otherChecked) services.add('other');

      if (services.isEmpty) {
        throw Exception('Vui lòng chọn ít nhất một dịch vụ');
      }

      // Create work order (photos will be uploaded inside repository)
      await repository.createWorkOrder(
        vehicleId: resolvedVehicleId,
        notes: state.notes,
        serviceTypes: services,
        technicianId: state.selectedTechnician,
        estimatedHours: double.tryParse(state.estimatedHours),
        photoFiles: state.photoFiles.isNotEmpty ? state.photoFiles : null,
      );
      
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: false,
        errorMessage: e.toString(),
      ));
    }
  }
}

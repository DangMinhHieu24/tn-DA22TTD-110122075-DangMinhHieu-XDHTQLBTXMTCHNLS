import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:admin/data/models/technician_model.dart';
import 'package:admin/data/models/work_order_model.dart';
import '../../../data/repositories/vehicle_intake_repository.dart';

part 'vehicle_intake_event.dart';
part 'vehicle_intake_state.dart';

class VehicleIntakeBloc extends Bloc<VehicleIntakeEvent, VehicleIntakeState> {
  final VehicleIntakeRepository repository;
  final ImageUploadService imageUploadService;
  final QRScannerService qrScannerService;

  VehicleIntakeBloc({
    required this.repository,
    required this.imageUploadService,
    required this.qrScannerService,
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
    on<VehicleIntakeQRScanned>(_onQRScanned);
    on<VehicleIntakeTechniciansRequested>(_onTechniciansRequested);
    on<VehicleIntakeOwnerNameChanged>(_onOwnerNameChanged);
    on<VehicleIntakeOwnerPhoneChanged>(_onOwnerPhoneChanged);
    on<VehicleIntakeVehicleTypeChanged>(_onVehicleTypeChanged);
    on<VehicleIntakeVehicleYearChanged>(_onVehicleYearChanged);
    on<VehicleIntakeVehicleColorChanged>(_onVehicleColorChanged);
    on<VehicleIntakeHistoryRequested>(_onHistoryRequested);
    on<ToggleHistoryExpanded>(_onToggleHistoryExpanded);
    on<VehicleIntakeAppointmentLinked>(_onAppointmentLinked);
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
      currentVehicleKm: null,
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
          warrantyStatus: vehicle.isUnderWarranty,
          ownerName: vehicle.ownerName ?? '',
          ownerPhone: vehicle.ownerPhone ?? '',
          currentVehicleKm: vehicle.currentKm,
        ));
        
        // Auto-load vehicle history
        add(VehicleIntakeHistoryRequested(vehicle.id));
      } else {
        emit(state.copyWith(
          isSearching: false,
          vehicleFound: false,
          vehicleHistory: [],
          historyExpanded: false,
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

  Future<void> _onQRScanned(
    VehicleIntakeQRScanned event,
    Emitter<VehicleIntakeState> emit,
  ) async {
    // QR scanning will be handled in the UI layer
    // This event is just a placeholder for future enhancements
  }

  void _onOwnerNameChanged(
    VehicleIntakeOwnerNameChanged event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(ownerName: event.ownerName));
  }

  void _onOwnerPhoneChanged(
    VehicleIntakeOwnerPhoneChanged event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(ownerPhone: event.ownerPhone));
  }

  void _onVehicleTypeChanged(
    VehicleIntakeVehicleTypeChanged event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(vehicleType: event.vehicleType));
  }

  void _onVehicleYearChanged(
    VehicleIntakeVehicleYearChanged event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(vehicleYear: event.vehicleYear));
  }

  void _onVehicleColorChanged(
    VehicleIntakeVehicleColorChanged event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(vehicleColor: event.vehicleColor));
  }

  Future<void> _onTechniciansRequested(
    VehicleIntakeTechniciansRequested event,
    Emitter<VehicleIntakeState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoadingTechnicians: true));
      final technicians = await repository.getTechnicians();
      emit(state.copyWith(
        isLoadingTechnicians: false,
        availableTechnicians: technicians,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingTechnicians: false,
        errorMessage: 'Không thể tải danh sách kỹ thuật viên: ${e.toString()}',
      ));
    }
  }

  Future<void> _onHistoryRequested(
    VehicleIntakeHistoryRequested event,
    Emitter<VehicleIntakeState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoadingHistory: true));
      
      final history = await repository.getVehicleHistory(event.vehicleId);
      
      emit(state.copyWith(
        isLoadingHistory: false,
        vehicleHistory: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingHistory: false,
        errorMessage: 'Không thể tải lịch sử: ${e.toString()}',
      ));
    }
  }

  void _onToggleHistoryExpanded(
    ToggleHistoryExpanded event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(
      historyExpanded: event.expanded,
    ));
  }

  void _onAppointmentLinked(
    VehicleIntakeAppointmentLinked event,
    Emitter<VehicleIntakeState> emit,
  ) {
    emit(state.copyWith(appointmentId: event.appointmentId));
  }

  Future<void> _onSubmitted(
    VehicleIntakeSubmitted event,
    Emitter<VehicleIntakeState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      // Validate KM input first
      final submittedKm = int.tryParse(state.km.trim().replaceAll(',', '').replaceAll('.', ''));
      if (submittedKm == null) {
        throw Exception('Vui lòng nhập số KM hợp lệ');
      }
      if (submittedKm < 0) {
        throw Exception('Số KM không hợp lệ');
      }

      // Resolve or create vehicle
      late String resolvedVehicleId;
      if (state.vehicleId == null) {
        final plate = state.licensePlate.trim();
        if (plate.isEmpty) {
          throw Exception('Vui lòng nhập biển số xe');
        }

        final vehicle = await repository.searchVehicle(plate);
        if (vehicle != null) {
          // Existing vehicle: validate KM is not less than recorded
          final existingKm = vehicle.currentKm;
          if (existingKm != null && submittedKm < existingKm) {
            throw Exception('Số KM mới không được nhỏ hơn số KM hiện tại (${existingKm} km)');
          }

          resolvedVehicleId = vehicle.id;
          emit(state.copyWith(
            vehicleId: resolvedVehicleId,
            vehicleFound: true,
            vehicleModel: vehicle.model,
            vehicleColor: vehicle.color,
            warrantyStatus: vehicle.isUnderWarranty,
            ownerName: vehicle.ownerName ?? '',
            ownerPhone: vehicle.ownerPhone ?? '',
            currentVehicleKm: vehicle.currentKm,
          ));
        } else {
          // New vehicle: validate new vehicle fields
          if (state.ownerName.trim().isEmpty) {
            throw Exception('Vui lòng nhập tên chủ xe');
          }
          if (state.ownerPhone.trim().isEmpty) {
            throw Exception('Vui lòng nhập số điện thoại chủ xe');
          }
          if (state.vehicleType.trim().isEmpty) {
            throw Exception('Vui lòng nhập loại xe');
          }

          final ownerId = await repository.createVehicleOwner(
            name: state.ownerName.trim(),
            phoneNumber: state.ownerPhone.trim(),
          );

          final newVehicle = await repository.createVehicle(
            licensePlate: plate,
            ownerId: ownerId,
            model: state.vehicleType.trim(),
            color: state.vehicleColor?.trim().isNotEmpty == true ? state.vehicleColor!.trim() : null,
            warrantyExpiry: null,
            currentKm: submittedKm,
          );

          resolvedVehicleId = newVehicle.id;
          emit(state.copyWith(
            vehicleId: resolvedVehicleId,
            vehicleFound: true,
            vehicleModel: newVehicle.model,
            vehicleColor: newVehicle.color,
            warrantyStatus: newVehicle.isUnderWarranty,
            currentVehicleKm: newVehicle.currentKm,
          ));
        }
      } else {
        // Vehicle already selected in state; ensure KM is valid vs state
        resolvedVehicleId = state.vehicleId!;
        final existingKm = state.currentVehicleKm;
        if (existingKm != null && submittedKm < existingKm) {
          throw Exception('Số KM mới không được nhỏ hơn số KM hiện tại (${existingKm} km)');
        }
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

      final estimatedHours = double.tryParse(state.estimatedHours.replaceAll(',', '.'));
      if (estimatedHours == null || estimatedHours <= 0) {
        throw Exception('Thời gian hoàn thành phải lớn hơn 0 giờ');
      }

      // Create work order (photos will be uploaded inside repository)
      await repository.createWorkOrder(
        vehicleId: resolvedVehicleId,
        notes: state.notes,
        serviceTypes: services,
        technicianId: state.selectedTechnician,
        estimatedHours: estimatedHours,
        photoFiles: state.photoFiles.isNotEmpty ? state.photoFiles : null,
        currentKm: submittedKm,
        appointmentId: state.appointmentId,
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

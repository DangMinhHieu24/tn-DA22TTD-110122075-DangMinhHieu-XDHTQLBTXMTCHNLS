part of 'vehicle_intake_bloc.dart';

class VehicleIntakeState extends Equatable {
  final String licensePlate;
  final String km;
  final bool maintenanceChecked;
  final bool batteryChecked;
  final bool brakesChecked;
  final bool otherChecked;
  final String notes;
  final String selectedTechnician;
  final String estimatedHours;
  final List<File> photoFiles; // Changed from List<String> to List<File>
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  
  // Vehicle search fields
  final bool isSearching;
  final bool vehicleFound;
  final String? vehicleId;
  final String? vehicleModel;
  final String? vehicleColor;
  final bool? warrantyStatus;
  
  // New vehicle form fields
  final String ownerName;
  final String ownerPhone;
  final String vehicleType;
  final String vehicleYear;
  
  // Technicians
  final List<TechnicianModel> availableTechnicians;
  final bool isLoadingTechnicians;

  // Vehicle history
  final List<WorkOrderModel> vehicleHistory;
  final bool isLoadingHistory;

  const VehicleIntakeState({
    this.licensePlate = '',
    this.km = '',
    this.maintenanceChecked = true,
    this.batteryChecked = false,
    this.brakesChecked = true,
    this.otherChecked = false,
    this.notes = '',
    this.selectedTechnician = 'auto',
    this.estimatedHours = '2.5',
    this.photoFiles = const [],
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.isSearching = false,
    this.vehicleFound = false,
    this.vehicleId,
    this.vehicleModel,
    this.vehicleColor,
    this.warrantyStatus,
    this.ownerName = '',
    this.ownerPhone = '',
    this.vehicleType = '',
    this.vehicleYear = '',
    this.availableTechnicians = const <TechnicianModel>[],
    this.isLoadingTechnicians = false,
    this.vehicleHistory = const <WorkOrderModel>[],
    this.isLoadingHistory = false,
  });

  VehicleIntakeState copyWith({
    String? licensePlate,
    String? km,
    bool? maintenanceChecked,
    bool? batteryChecked,
    bool? brakesChecked,
    bool? otherChecked,
    String? notes,
    String? selectedTechnician,
    String? estimatedHours,
    List<File>? photoFiles,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool? isSearching,
    bool? vehicleFound,
    String? vehicleId,
    String? vehicleModel,
    String? vehicleColor,
    bool? warrantyStatus,
    String? ownerName,
    String? ownerPhone,
    String? vehicleType,
    String? vehicleYear,
    List<TechnicianModel>? availableTechnicians,
    bool? isLoadingTechnicians,
    List<WorkOrderModel>? vehicleHistory,
    bool? isLoadingHistory,
  }) {
    return VehicleIntakeState(
      licensePlate: licensePlate ?? this.licensePlate,
      km: km ?? this.km,
      maintenanceChecked: maintenanceChecked ?? this.maintenanceChecked,
      batteryChecked: batteryChecked ?? this.batteryChecked,
      brakesChecked: brakesChecked ?? this.brakesChecked,
      otherChecked: otherChecked ?? this.otherChecked,
      notes: notes ?? this.notes,
      selectedTechnician: selectedTechnician ?? this.selectedTechnician,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      photoFiles: photoFiles ?? this.photoFiles,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      isSearching: isSearching ?? this.isSearching,
      vehicleFound: vehicleFound ?? this.vehicleFound,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      warrantyStatus: warrantyStatus ?? this.warrantyStatus,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      availableTechnicians: availableTechnicians ?? this.availableTechnicians,
      isLoadingTechnicians: isLoadingTechnicians ?? this.isLoadingTechnicians,
      vehicleHistory: vehicleHistory ?? this.vehicleHistory,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }

  @override
  List<Object?> get props => [
        licensePlate,
        km,
        maintenanceChecked,
        batteryChecked,
        brakesChecked,
        otherChecked,
        notes,
        selectedTechnician,
        estimatedHours,
        photoFiles,
        isSubmitting,
        isSuccess,
        errorMessage,
        isSearching,
        vehicleFound,
        vehicleId,
        vehicleModel,
        vehicleColor,
        warrantyStatus,
        ownerName,
        ownerPhone,
        vehicleType,
        vehicleYear,
        availableTechnicians,
        isLoadingTechnicians,
        vehicleHistory,
        isLoadingHistory,
      ];
}

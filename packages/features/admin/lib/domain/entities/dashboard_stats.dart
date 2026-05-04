import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int vehiclesInService;
  final int completedToday;
  final double revenueToday;
  final List<double> weeklyRevenue;
  final List<SystemAlert> alerts;
  final List<TechnicianStatus> technicians;

  const DashboardStats({
    required this.vehiclesInService,
    required this.completedToday,
    required this.revenueToday,
    required this.weeklyRevenue,
    required this.alerts,
    required this.technicians,
  });

  @override
  List<Object?> get props => [
        vehiclesInService,
        completedToday,
        revenueToday,
        weeklyRevenue,
        alerts,
        technicians,
      ];
}

class SystemAlert extends Equatable {
  final String id;
  final String title;
  final String description;
  final AlertType type;
  final DateTime createdAt;

  const SystemAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, description, type, createdAt];
}

enum AlertType {
  lowStock,
  delayedVehicle,
  warrantyExpiring,
}

class TechnicianStatus extends Equatable {
  final String id;
  final String name;
  final String status;
  final int activeVehicles;

  const TechnicianStatus({
    required this.id,
    required this.name,
    required this.status,
    required this.activeVehicles,
  });

  @override
  List<Object?> get props => [id, name, status, activeVehicles];
}

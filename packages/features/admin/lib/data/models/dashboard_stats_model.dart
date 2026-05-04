import '../../domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.vehiclesInService,
    required super.completedToday,
    required super.revenueToday,
    required super.weeklyRevenue,
    required super.alerts,
    required super.technicians,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      vehiclesInService: json['vehiclesInService'] as int,
      completedToday: json['completedToday'] as int,
      revenueToday: (json['revenueToday'] as num).toDouble(),
      weeklyRevenue: (json['weeklyRevenue'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      alerts: (json['alerts'] as List)
          .map((e) => SystemAlertModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      technicians: (json['technicians'] as List)
          .map((e) => TechnicianStatusModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehiclesInService': vehiclesInService,
      'completedToday': completedToday,
      'revenueToday': revenueToday,
      'weeklyRevenue': weeklyRevenue,
      'alerts': alerts.map((e) => (e as SystemAlertModel).toJson()).toList(),
      'technicians': technicians.map((e) => (e as TechnicianStatusModel).toJson()).toList(),
    };
  }
}

class SystemAlertModel extends SystemAlert {
  const SystemAlertModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    required super.createdAt,
  });

  factory SystemAlertModel.fromJson(Map<String, dynamic> json) {
    return SystemAlertModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.lowStock,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class TechnicianStatusModel extends TechnicianStatus {
  const TechnicianStatusModel({
    required super.id,
    required super.name,
    required super.status,
    required super.activeVehicles,
  });

  factory TechnicianStatusModel.fromJson(Map<String, dynamic> json) {
    return TechnicianStatusModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      activeVehicles: json['activeVehicles'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'activeVehicles': activeVehicles,
    };
  }
}

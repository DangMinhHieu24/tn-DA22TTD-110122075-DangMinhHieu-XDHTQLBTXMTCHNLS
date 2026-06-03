import '../../domain/entities/revenue_report.dart';

class RevenueReportModel extends RevenueReport {
  const RevenueReportModel({
    required super.rangeStart,
    required super.rangeEnd,
    required super.totalRevenue,
    required super.previousTotalRevenue,
    required super.growthPercent,
    required super.totalOrders,
    required super.dailyRevenue,
    required super.topServices,
    required super.technicians,
  });

  factory RevenueReportModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return RevenueReportModel(
      rangeStart: DateTime.parse(payload['rangeStart'] as String),
      rangeEnd: DateTime.parse(payload['rangeEnd'] as String),
      totalRevenue: (payload['totalRevenue'] as num?)?.toDouble() ?? 0,
      previousTotalRevenue: (payload['previousTotalRevenue'] as num?)?.toDouble() ?? 0,
      growthPercent: (payload['growthPercent'] as num?)?.toDouble() ?? 0,
      totalOrders: (payload['totalOrders'] as num?)?.toInt() ?? 0,
      dailyRevenue: (payload['dailyRevenue'] as List? ?? const [])
          .map((e) => RevenuePointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      topServices: (payload['topServices'] as List? ?? const [])
          .map((e) => ServiceBreakdownModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      technicians: (payload['technicians'] as List? ?? const [])
          .map((e) => TechnicianBreakdownModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RevenuePointModel extends RevenuePoint {
  const RevenuePointModel({
    required super.date,
    required super.revenue,
    required super.orders,
  });

  factory RevenuePointModel.fromJson(Map<String, dynamic> json) {
    return RevenuePointModel(
      date: DateTime.parse(json['date'] as String),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );
  }
}

class ServiceBreakdownModel extends ServiceBreakdown {
  const ServiceBreakdownModel({
    required super.name,
    required super.revenue,
    required super.percent,
  });

  factory ServiceBreakdownModel.fromJson(Map<String, dynamic> json) {
    return ServiceBreakdownModel(
      name: json['name'] as String? ?? 'Khac',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TechnicianBreakdownModel extends TechnicianBreakdown {
  const TechnicianBreakdownModel({
    required super.id,
    required super.name,
    required super.revenue,
    required super.orders,
    required super.activeOrders,
  });

  factory TechnicianBreakdownModel.fromJson(Map<String, dynamic> json) {
    return TechnicianBreakdownModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Khong ro',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      activeOrders: (json['activeOrders'] as num?)?.toInt() ?? 0,
    );
  }
}

import 'package:equatable/equatable.dart';

class RevenueReport extends Equatable {
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double totalRevenue;
  final double previousTotalRevenue;
  final double growthPercent;
  final int totalOrders;
  final List<RevenuePoint> dailyRevenue;
  final List<ServiceBreakdown> topServices;
  final List<TechnicianBreakdown> technicians;

  const RevenueReport({
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalRevenue,
    required this.previousTotalRevenue,
    required this.growthPercent,
    required this.totalOrders,
    required this.dailyRevenue,
    required this.topServices,
    required this.technicians,
  });

  @override
  List<Object?> get props => [
        rangeStart,
        rangeEnd,
        totalRevenue,
        previousTotalRevenue,
        growthPercent,
        totalOrders,
        dailyRevenue,
        topServices,
        technicians,
      ];
}

class RevenuePoint extends Equatable {
  final DateTime date;
  final double revenue;
  final int orders;

  const RevenuePoint({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  @override
  List<Object?> get props => [date, revenue, orders];
}

class ServiceBreakdown extends Equatable {
  final String name;
  final double revenue;
  final double percent;

  const ServiceBreakdown({
    required this.name,
    required this.revenue,
    required this.percent,
  });

  @override
  List<Object?> get props => [name, revenue, percent];
}

class TechnicianBreakdown extends Equatable {
  final String id;
  final String name;
  final double revenue;
  final int orders;
  final int activeOrders;

  const TechnicianBreakdown({
    required this.id,
    required this.name,
    required this.revenue,
    required this.orders,
    this.activeOrders = 0,
  });

  @override
  List<Object?> get props => [id, name, revenue, orders, activeOrders];
}

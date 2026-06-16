class WorkHistoryItem {
  final String orderNumber;
  final String? status;
  final String? notes;
  final DateTime? createdAt;
  final String? licensePlate;
  final String? description;
  final double? totalCost;

  const WorkHistoryItem({
    required this.orderNumber,
    this.status,
    this.notes,
    this.createdAt,
    this.licensePlate,
    this.description,
    this.totalCost,
  });
}

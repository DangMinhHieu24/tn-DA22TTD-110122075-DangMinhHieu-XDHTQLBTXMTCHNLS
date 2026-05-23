class WorkItemService {
  final String id;
  final String serviceType;
  final String? serviceName;
  final String? description;
  final double? price;
  final bool isDone;
  final String? note;
  final DateTime createdAt;

  WorkItemService({
    required this.id,
    required this.serviceType,
    this.serviceName,
    this.description,
    this.price,
    required this.isDone,
    this.note,
    required this.createdAt,
  });
}

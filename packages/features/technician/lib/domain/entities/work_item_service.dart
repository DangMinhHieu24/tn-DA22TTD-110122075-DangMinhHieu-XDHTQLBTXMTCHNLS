class WorkItemService {
  final String id;
  final String serviceType;
  final String? serviceName;
  final String? description;
  final double? price;
  final bool isDone;
  final String? note;
  final String approvalStatus; // 'PENDING', 'APPROVED', 'REJECTED'
  final DateTime createdAt;

  WorkItemService({
    required this.id,
    required this.serviceType,
    this.serviceName,
    this.description,
    this.price,
    required this.isDone,
    this.note,
    this.approvalStatus = 'APPROVED',
    required this.createdAt,
  });

  bool get isPending => approvalStatus == 'PENDING';
  bool get isApproved => approvalStatus == 'APPROVED';
  bool get isRejected => approvalStatus == 'REJECTED';
}

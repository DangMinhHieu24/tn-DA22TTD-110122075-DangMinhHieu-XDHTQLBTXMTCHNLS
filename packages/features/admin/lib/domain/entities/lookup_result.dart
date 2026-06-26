/// Base entity cho kết quả tra cứu.
abstract class LookupResult {
  final String id;
  final String categoryId;

  const LookupResult({
    required this.id,
    required this.categoryId,
  });
}

/// Kết quả tra cứu xe — chứa đủ thông tin để hiển thị card + detail.
class VehicleLookupResult extends LookupResult {
  final String licensePlate;
  final String? brand;
  final String model;
  final String? color;
  final String? imageUrl;
  final int? manufactureYear;
  final int? currentKm;
  final DateTime? warrantyExpiry;
  final String ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final DateTime createdAt;

  const VehicleLookupResult({
    required super.id,
    required super.categoryId,
    required this.licensePlate,
    this.brand,
    required this.model,
    this.color,
    this.imageUrl,
    this.manufactureYear,
    this.currentKm,
    this.warrantyExpiry,
    required this.ownerId,
    this.ownerName,
    this.ownerPhone,
    required this.createdAt,
  });

  bool get isUnderWarranty {
    if (warrantyExpiry == null) return false;
    return DateTime.now().isBefore(warrantyExpiry!);
  }

  String get displayName => '${brand ?? ''} $model'.trim();
}

/// Kết quả tra cứu khách hàng.
class CustomerLookupResult extends LookupResult {
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final int loyaltyPoints;
  final int treesPlanted;
  final int vehicleCount;
  final DateTime createdAt;

  const CustomerLookupResult({
    required super.id,
    required super.categoryId,
    required this.name,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.loyaltyPoints = 0,
    this.treesPlanted = 0,
    this.vehicleCount = 0,
    required this.createdAt,
  });
}

/// Kết quả tra cứu nhân viên (kỹ thuật viên).
class TechnicianLookupResult extends LookupResult {
  final String name;
  final String? phoneNumber;
  final int activeJobCount;
  final bool isOnline;
  final DateTime updatedAt;
  final int thisMonthCompletedCount;
  final num thisMonthRevenue;
  final int lastMonthCompletedCount;
  final num lastMonthRevenue;

  const TechnicianLookupResult({
    required super.id,
    required super.categoryId,
    required this.name,
    this.phoneNumber,
    this.activeJobCount = 0,
    this.isOnline = false,
    required this.updatedAt,
    this.thisMonthCompletedCount = 0,
    this.thisMonthRevenue = 0,
    this.lastMonthCompletedCount = 0,
    this.lastMonthRevenue = 0,
  });
}

/// Kết quả tra cứu hoá đơn (work order đã hoàn thành/đã thanh toán).
class InvoiceLookupResult extends LookupResult {
  final String orderNumber;
  final String status;
  final double? totalPrice;
  final String? paymentMethod;
  final DateTime? paidAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String? notes;

  // Vehicle info
  final String vehicleId;
  final String? licensePlate;
  final String? vehicleBrand;
  final String? vehicleModel;

  // Customer info
  final String? customerName;
  final String? customerPhone;

  // Technician
  final String? technicianName;

  // Breakdown
  final List<InvoiceServiceItem> services;
  final List<InvoicePartItem> partsUsed;

  const InvoiceLookupResult({
    required super.id,
    required super.categoryId,
    required this.orderNumber,
    required this.status,
    this.totalPrice,
    this.paymentMethod,
    this.paidAt,
    this.completedAt,
    required this.createdAt,
    this.notes,
    required this.vehicleId,
    this.licensePlate,
    this.vehicleBrand,
    this.vehicleModel,
    this.customerName,
    this.customerPhone,
    this.technicianName,
    this.services = const [],
    this.partsUsed = const [],
  });

  bool get isPaid => status == 'PAID';
}

class InvoiceServiceItem {
  final String serviceType;
  final String? serviceName;
  final String? description;
  final double? price;

  const InvoiceServiceItem({
    required this.serviceType,
    this.serviceName,
    this.description,
    this.price,
  });
}

class InvoicePartItem {
  final String partName;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;

  const InvoicePartItem({
    required this.partName,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
  });
}

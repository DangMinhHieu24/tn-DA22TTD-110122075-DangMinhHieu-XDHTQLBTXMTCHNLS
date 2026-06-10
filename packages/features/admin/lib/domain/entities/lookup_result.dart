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

  const TechnicianLookupResult({
    required super.id,
    required super.categoryId,
    required this.name,
    this.phoneNumber,
    this.activeJobCount = 0,
    this.isOnline = false,
    required this.updatedAt,
  });
}

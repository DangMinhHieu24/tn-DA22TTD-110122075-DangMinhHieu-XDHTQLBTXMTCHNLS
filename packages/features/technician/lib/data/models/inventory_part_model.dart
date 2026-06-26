import '../../domain/entities/inventory_part.dart';

class InventoryPartModel extends InventoryPart {
  const InventoryPartModel({
    required super.id,
    required super.partName,
    super.imageUrl,
    required super.quantity,
    required super.minThreshold,
    required super.unitPrice,
    required super.sellPrice,
    super.warrantyDays,
  });

  factory InventoryPartModel.fromApiJson(Map<String, dynamic> json) {
    return InventoryPartModel(
      id: json['id'] as String? ?? '',
      partName: json['partName'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      minThreshold: json['minThreshold'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      sellPrice: (json['sellPrice'] as num?)?.toDouble() ?? 0,
      warrantyDays: json['warrantyDays'] as int?,
    );
  }
}

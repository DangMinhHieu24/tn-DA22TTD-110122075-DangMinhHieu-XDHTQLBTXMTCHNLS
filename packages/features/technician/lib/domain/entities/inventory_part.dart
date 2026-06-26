import 'package:equatable/equatable.dart';

class InventoryPart extends Equatable {
  final String id;
  final String partName;
  final String? imageUrl;
  final int quantity;
  final int minThreshold;
  final double unitPrice;
  final double sellPrice;
  final int? warrantyDays;

  const InventoryPart({
    required this.id,
    required this.partName,
    this.imageUrl,
    required this.quantity,
    required this.minThreshold,
    required this.unitPrice,
    required this.sellPrice,
    this.warrantyDays,
  });

  bool get isLowStock => quantity <= minThreshold;
  bool get isOutOfStock => quantity == 0;

  @override
  List<Object?> get props => [
        id, partName, imageUrl, quantity, minThreshold,
        unitPrice, sellPrice, warrantyDays,
      ];
}

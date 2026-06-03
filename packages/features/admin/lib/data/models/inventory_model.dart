class InventoryModel {
  final String id;
  final String partName;
  final String? imageUrl;
  final int quantity;
  final int minThreshold;
  final double unitPrice;
  final double sellPrice;

  const InventoryModel({
    required this.id,
    required this.partName,
    this.imageUrl,
    required this.quantity,
    required this.minThreshold,
    required this.unitPrice,
    required this.sellPrice,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'] as String,
      partName: json['partName'] as String,
      imageUrl: json['imageUrl'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      minThreshold: (json['minThreshold'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      sellPrice: (json['sellPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partName': partName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'minThreshold': minThreshold,
      'unitPrice': unitPrice,
      'sellPrice': sellPrice,
    };
  }

  /// Tồn kho đang ở mức cảnh báo
  bool get isBelowThreshold => quantity <= minThreshold;

  /// Tồn kho đang ở mức gần cảnh báo (< threshold * 1.5)
  bool get isNearThreshold => quantity <= minThreshold * 1.5 && quantity > minThreshold;

  InventoryModel copyWith({
    String? id,
    String? partName,
    String? imageUrl,
    int? quantity,
    int? minThreshold,
    double? unitPrice,
    double? sellPrice,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      partName: partName ?? this.partName,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      minThreshold: minThreshold ?? this.minThreshold,
      unitPrice: unitPrice ?? this.unitPrice,
      sellPrice: sellPrice ?? this.sellPrice,
    );
  }
}

class InventoryModel {
  final String id;
  final String partName;
  final String? imageUrl;
  final int quantity;
  final int minThreshold;
  final double unitPrice;
  final double sellPrice;
  final int warrantyDays;

  const InventoryModel({
    required this.id,
    required this.partName,
    this.imageUrl,
    required this.quantity,
    required this.minThreshold,
    required this.unitPrice,
    required this.sellPrice,
    this.warrantyDays = 0,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'] as String? ?? '',
      partName: json['partName'] as String? ?? 'Không rõ',
      imageUrl: json['imageUrl'] as String?,
      quantity: _asInt(json['quantity']),
      minThreshold: _asInt(json['minThreshold']),
      unitPrice: _asDouble(json['unitPrice']),
      sellPrice: _asDouble(json['sellPrice']),
      warrantyDays: _asInt(json['warrantyDays']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'partName': partName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'minThreshold': minThreshold,
      'unitPrice': unitPrice,
      'sellPrice': sellPrice,
      'warrantyDays': warrantyDays,
    };
  }

  /// Tồn kho đang ở mức cảnh báo
  bool get isBelowThreshold => quantity <= minThreshold;

  /// Tồn kho đang ở mức gần cảnh báo (< threshold * 1.5)
  bool get isNearThreshold =>
      quantity <= minThreshold * 1.5 && quantity > minThreshold;

  InventoryModel copyWith({
    String? id,
    String? partName,
    String? imageUrl,
    int? quantity,
    int? minThreshold,
    double? unitPrice,
    double? sellPrice,
    int? warrantyDays,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      partName: partName ?? this.partName,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      minThreshold: minThreshold ?? this.minThreshold,
      unitPrice: unitPrice ?? this.unitPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      warrantyDays: warrantyDays ?? this.warrantyDays,
    );
  }
}

class TechnicianModel {
  final String id;
  final String name;
  final String? phoneNumber;
  final int vehicleCount;
  final bool isOnline;

  const TechnicianModel({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.vehicleCount = 0,
    this.isOnline = false,
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    return TechnicianModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      vehicleCount: json['vehicleCount'] is int
          ? json['vehicleCount'] as int
          : (json['vehicleCount'] != null ? int.tryParse(json['vehicleCount'].toString()) ?? 0 : 0),
      isOnline: json['isOnline'] == true,
    );
  }
}

class TechnicianModel {
  final String id;
  final String name;
  final String? phoneNumber;

  const TechnicianModel({
    required this.id,
    required this.name,
    this.phoneNumber,
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    return TechnicianModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }
}

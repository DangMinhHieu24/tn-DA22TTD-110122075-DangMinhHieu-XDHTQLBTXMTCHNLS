import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.phoneNumber,
    super.avatarUrl,
    super.loyaltyPoints,
    super.treesPlanted,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: _roleFromString(json['role'] as String),
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
      treesPlanted: json['treesPlanted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': _roleToString(role),
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'loyaltyPoints': loyaltyPoints,
      'treesPlanted': treesPlanted,
    };
  }

  static UserRole _roleFromString(String role) {
    switch (role.toUpperCase()) {
      case 'STAFF':
      case 'ADMIN':
        return UserRole.staff;
      case 'TECHNICIAN':
        return UserRole.technician;
      case 'CUSTOMER':
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.staff:
        return 'STAFF';
      case UserRole.technician:
        return 'TECHNICIAN';
      case UserRole.customer:
        return 'CUSTOMER';
    }
  }
}

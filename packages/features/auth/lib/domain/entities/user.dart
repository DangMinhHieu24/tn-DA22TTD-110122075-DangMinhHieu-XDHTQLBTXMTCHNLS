import 'package:equatable/equatable.dart';

enum UserRole { staff, technician, customer }

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final String? avatarUrl;
  final int loyaltyPoints;
  final int treesPlanted;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.avatarUrl,
    this.loyaltyPoints = 0,
    this.treesPlanted = 0,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? phoneNumber,
    String? avatarUrl,
    int? loyaltyPoints,
    int? treesPlanted,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      treesPlanted: treesPlanted ?? this.treesPlanted,
    );
  }

  @override
  List<Object?> get props => [id, email, name, role, phoneNumber, avatarUrl, loyaltyPoints, treesPlanted];
}

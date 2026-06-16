import 'package:equatable/equatable.dart';

enum UserRole { staff, technician, customer }

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, email, name, role, phoneNumber, avatarUrl];
}

import 'package:equatable/equatable.dart';
import 'package:auth/domain/entities/user.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User? user;

  const ProfileLoaded({this.user});

  @override
  List<Object?> get props => [user];
}

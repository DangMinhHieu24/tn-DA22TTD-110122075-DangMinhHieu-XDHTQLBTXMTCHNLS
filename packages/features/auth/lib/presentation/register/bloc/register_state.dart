part of 'register_bloc.dart';

abstract class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object> get props => [];
}

class RegisterInitial extends RegisterState {
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;

  const RegisterInitial({
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
  });

  @override
  List<Object> get props => [isPasswordVisible, isConfirmPasswordVisible];
}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final User user;

  const RegisterSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

class RegisterFailure extends RegisterState {
  final String message;

  const RegisterFailure({required this.message});

  @override
  List<Object> get props => [message];
}

part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object> get props => [];
}

class RegisterSubmitted extends RegisterEvent {
  final String name;
  final String phoneNumber;
  final String email;
  final String password;
  final String confirmPassword;

  const RegisterSubmitted({
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object> get props => [name, phoneNumber, email, password, confirmPassword];
}

class RegisterPasswordVisibilityToggled extends RegisterEvent {
  const RegisterPasswordVisibilityToggled();
}

class RegisterConfirmPasswordVisibilityToggled extends RegisterEvent {
  const RegisterConfirmPasswordVisibilityToggled();
}

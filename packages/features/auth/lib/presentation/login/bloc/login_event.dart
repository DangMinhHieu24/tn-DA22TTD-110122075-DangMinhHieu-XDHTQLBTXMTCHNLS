part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginSubmitted extends LoginEvent {
  final String identifier;
  final String password;

  const LoginSubmitted({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object> get props => [identifier, password];
}

class LoginPasswordVisibilityToggled extends LoginEvent {
  const LoginPasswordVisibilityToggled();
}

class LoginRememberMeToggled extends LoginEvent {
  final bool rememberMe;
  
  const LoginRememberMeToggled(this.rememberMe);
  
  @override
  List<Object> get props => [rememberMe];
}

class LoginCredentialsLoaded extends LoginEvent {
  const LoginCredentialsLoaded();
}

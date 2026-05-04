part of 'login_bloc.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  final bool isPasswordVisible;
  final bool rememberMe;
  final String? savedIdentifier;
  final String? savedPassword;

  const LoginInitial({
    this.isPasswordVisible = false,
    this.rememberMe = false,
    this.savedIdentifier,
    this.savedPassword,
  });

  LoginInitial copyWith({
    bool? isPasswordVisible,
    bool? rememberMe,
    String? savedIdentifier,
    String? savedPassword,
  }) {
    return LoginInitial(
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      rememberMe: rememberMe ?? this.rememberMe,
      savedIdentifier: savedIdentifier ?? this.savedIdentifier,
      savedPassword: savedPassword ?? this.savedPassword,
    );
  }

  @override
  List<Object?> get props => [isPasswordVisible, rememberMe, savedIdentifier, savedPassword];
}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final User user;

  const LoginSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

class LoginFailure extends LoginState {
  final String message;

  const LoginFailure({required this.message});

  @override
  List<Object> get props => [message];
}

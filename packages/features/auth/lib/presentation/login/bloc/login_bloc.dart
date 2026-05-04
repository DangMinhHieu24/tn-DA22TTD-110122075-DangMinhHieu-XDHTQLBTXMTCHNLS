import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  final AuthLocalDataSource localDataSource;

  LoginBloc({
    required this.loginUseCase,
    required this.localDataSource,
  }) : super(const LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<LoginRememberMeToggled>(_onRememberMeToggled);
    on<LoginCredentialsLoaded>(_onCredentialsLoaded);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // Save rememberMe state before emitting loading
    final shouldRemember = state is LoginInitial ? (state as LoginInitial).rememberMe : false;
    
    emit(LoginLoading());

    final result = await loginUseCase(
      LoginParams(
        identifier: event.identifier,
        password: event.password,
      ),
    );

    await result.fold(
      (failure) async => emit(LoginFailure(message: failure.message)),
      (user) async {
        // Save credentials if remember me is checked
        if (shouldRemember) {
          await localDataSource.saveCredentials(event.identifier, event.password);
          await localDataSource.setRememberMe(true);
        } else {
          await localDataSource.deleteCredentials();
          await localDataSource.setRememberMe(false);
        }
        
        emit(LoginSuccess(user: user));
      },
    );
  }

  void _onPasswordVisibilityToggled(
    LoginPasswordVisibilityToggled event,
    Emitter<LoginState> emit,
  ) {
    if (state is LoginInitial) {
      final currentState = state as LoginInitial;
      emit(currentState.copyWith(isPasswordVisible: !currentState.isPasswordVisible));
    }
  }

  void _onRememberMeToggled(
    LoginRememberMeToggled event,
    Emitter<LoginState> emit,
  ) {
    if (state is LoginInitial) {
      final currentState = state as LoginInitial;
      emit(currentState.copyWith(rememberMe: !currentState.rememberMe));
    }
  }

  Future<void> _onCredentialsLoaded(
    LoginCredentialsLoaded event,
    Emitter<LoginState> emit,
  ) async {
    final rememberMe = await localDataSource.getRememberMe();
    if (rememberMe) {
      final credentials = await localDataSource.getCredentials();
      if (credentials != null) {
        emit(LoginInitial(
          rememberMe: true,
          savedIdentifier: credentials['identifier'],
          savedPassword: credentials['password'],
        ));
        return;
      }
    }
    emit(const LoginInitial());
  }
}

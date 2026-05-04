import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/register_usecase.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterUseCase registerUseCase;

  RegisterBloc({required this.registerUseCase}) : super(RegisterInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<RegisterPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<RegisterConfirmPasswordVisibilityToggled>(_onConfirmPasswordVisibilityToggled);
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());

    final result = await registerUseCase(
      RegisterParams(
        name: event.name,
        phoneNumber: event.phoneNumber,
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
      ),
    );

    result.fold(
      (failure) => emit(RegisterFailure(message: failure.message)),
      (user) => emit(RegisterSuccess(user: user)),
    );
  }

  void _onPasswordVisibilityToggled(
    RegisterPasswordVisibilityToggled event,
    Emitter<RegisterState> emit,
  ) {
    if (state is RegisterInitial) {
      final currentState = state as RegisterInitial;
      emit(RegisterInitial(
        isPasswordVisible: !currentState.isPasswordVisible,
        isConfirmPasswordVisible: currentState.isConfirmPasswordVisible,
      ));
    }
  }

  void _onConfirmPasswordVisibilityToggled(
    RegisterConfirmPasswordVisibilityToggled event,
    Emitter<RegisterState> emit,
  ) {
    if (state is RegisterInitial) {
      final currentState = state as RegisterInitial;
      emit(RegisterInitial(
        isPasswordVisible: currentState.isPasswordVisible,
        isConfirmPasswordVisible: !currentState.isConfirmPasswordVisible,
      ));
    }
  }
}

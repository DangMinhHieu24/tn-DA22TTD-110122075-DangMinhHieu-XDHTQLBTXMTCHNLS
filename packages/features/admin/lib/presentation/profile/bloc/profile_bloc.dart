import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth/presentation/bloc/auth_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthBloc _authBloc;

  ProfileBloc({required AuthBloc authBloc})
      : _authBloc = authBloc,
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<LogoutRequested>(_onLogoutRequested);
  }

  void _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      emit(ProfileLoaded(user: authState.user));
    } else {
      emit(const ProfileLoaded());
    }
  }

  void _onLogoutRequested(
    LogoutRequested event,
    Emitter<ProfileState> emit,
  ) {
    _authBloc.add(const AuthLogoutRequested());
  }
}

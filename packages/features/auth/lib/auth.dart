library auth;

// DI
export 'di/auth_di.dart';

// Domain
export 'domain/entities/user.dart';
export 'domain/repositories/auth_repository.dart';
export 'domain/usecases/login_usecase.dart';
export 'domain/usecases/register_usecase.dart';
export 'domain/usecases/logout_usecase.dart';
export 'domain/usecases/get_current_user_usecase.dart';

// Data
export 'data/models/user_model.dart';
export 'data/models/auth_response_model.dart';
export 'data/repositories/auth_repository_impl.dart';
export 'data/datasources/local/auth_local_datasource.dart';
export 'data/datasources/remote/auth_remote_datasource.dart';
export 'data/interceptors/auth_interceptor.dart';

// Presentation - BLoC
export 'presentation/bloc/auth_bloc.dart';
export 'presentation/login/bloc/login_bloc.dart';
export 'presentation/register/bloc/register_bloc.dart';

// Presentation - Pages
export 'presentation/login/pages/login_page.dart';
export 'presentation/register/pages/register_page.dart';

// Presentation - Widgets (Shared)
export 'presentation/widgets/logout_button.dart';
export 'presentation/widgets/user_avatar.dart';

// Presentation - Widgets (Login)
export 'presentation/login/widgets/remember_me_checkbox.dart';

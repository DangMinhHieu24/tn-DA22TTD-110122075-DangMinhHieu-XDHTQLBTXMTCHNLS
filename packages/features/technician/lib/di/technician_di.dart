import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../domain/repositories/work_repository.dart';
import '../domain/usecases/get_work_items_usecase.dart';
import '../domain/usecases/search_work_items_usecase.dart';
import '../domain/usecases/update_work_status_usecase.dart';
import '../presentation/dashboard/bloc/dashboard_bloc.dart';
import '../data/repositories/work_repository_impl.dart';
import '../data/datasources/local/work_local_datasource.dart';
import '../data/datasources/remote/work_remote_datasource.dart';

final getIt = GetIt.instance;

void setupTechnicianDependencies() {
  // Data sources
  getIt.registerLazySingleton<WorkLocalDataSource>(
    () => WorkLocalDataSourceImpl(),
  );

  // Dio should already be registered by auth feature
  getIt.registerLazySingleton<WorkRemoteDataSource>(
    () => WorkRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  // Repository
  getIt.registerLazySingleton<WorkRepository>(
    () => WorkRepositoryImpl(
      remoteDataSource: getIt<WorkRemoteDataSource>(),
      localDataSource: getIt<WorkLocalDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<GetWorkItemsUseCase>(
    () => GetWorkItemsUseCase(getIt<WorkRepository>()),
  );

  getIt.registerLazySingleton<SearchWorkItemsUseCase>(
    () => SearchWorkItemsUseCase(getIt<WorkRepository>()),
  );

  getIt.registerLazySingleton<UpdateWorkStatusUseCase>(
    () => UpdateWorkStatusUseCase(getIt<WorkRepository>()),
  );

  // Presentation - Dashboard Bloc
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      getWorkItemsUseCase: getIt<GetWorkItemsUseCase>(),
      searchWorkItemsUseCase: getIt<SearchWorkItemsUseCase>(),
      updateWorkStatusUseCase: getIt<UpdateWorkStatusUseCase>(),
    ),
  );
}

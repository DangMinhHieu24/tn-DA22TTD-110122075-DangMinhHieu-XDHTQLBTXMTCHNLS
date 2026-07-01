import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../domain/repositories/work_repository.dart';
import '../domain/repositories/tech_lookup_repository.dart';
import '../domain/usecases/get_work_items_usecase.dart';
import '../domain/usecases/update_work_status_usecase.dart';
import '../domain/usecases/search_vehicle_by_plate_usecase.dart';
import '../domain/usecases/get_vehicle_warranties_usecase.dart';
import '../domain/usecases/get_all_vehicles_usecase.dart';
import '../domain/usecases/get_inventory_parts_usecase.dart';
import '../domain/usecases/search_work_orders_usecase.dart';
import '../presentation/dashboard/bloc/dashboard_bloc.dart';
import '../presentation/lookup/bloc/vehicle_detail_bloc.dart';
import '../presentation/lookup/bloc/vehicle_list_bloc.dart';
import '../presentation/lookup/bloc/parts_lookup_bloc.dart';
import '../presentation/lookup/bloc/work_order_search_bloc.dart';
import '../presentation/chat/bloc/tech_chat_bloc.dart';
import '../presentation/chat/domain/repositories/tech_chat_repository.dart';
import '../presentation/chat/data/repositories/tech_chat_repository_impl.dart';
import '../presentation/chat/data/datasources/tech_chat_remote_datasource.dart';
import '../data/repositories/work_repository_impl.dart';
import '../data/repositories/tech_lookup_repository_impl.dart';
import '../data/datasources/local/work_local_datasource.dart';
import '../data/datasources/remote/work_remote_datasource.dart';
import '../data/datasources/remote/tech_lookup_remote_datasource.dart';

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

  getIt.registerLazySingleton<TechLookupRemoteDataSource>(
    () => TechLookupRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  // Repositories
  getIt.registerLazySingleton<WorkRepository>(
    () => WorkRepositoryImpl(
      remoteDataSource: getIt<WorkRemoteDataSource>(),
      localDataSource: getIt<WorkLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton<TechLookupRepository>(
    () => TechLookupRepositoryImpl(
      remoteDataSource: getIt<TechLookupRemoteDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<GetWorkItemsUseCase>(
    () => GetWorkItemsUseCase(getIt<WorkRepository>()),
  );

  getIt.registerLazySingleton<UpdateWorkStatusUseCase>(
    () => UpdateWorkStatusUseCase(getIt<WorkRepository>()),
  );

  getIt.registerLazySingleton<SearchVehicleByPlateUseCase>(
    () => SearchVehicleByPlateUseCase(getIt<TechLookupRepository>()),
  );

  getIt.registerLazySingleton<GetVehicleWarrantiesUseCase>(
    () => GetVehicleWarrantiesUseCase(getIt<TechLookupRepository>()),
  );

  getIt.registerLazySingleton<GetAllVehiclesUseCase>(
    () => GetAllVehiclesUseCase(getIt<TechLookupRepository>()),
  );

  getIt.registerLazySingleton<GetInventoryPartsUseCase>(
    () => GetInventoryPartsUseCase(getIt<TechLookupRepository>()),
  );

  getIt.registerLazySingleton<SearchWorkOrdersUseCase>(
    () => SearchWorkOrdersUseCase(getIt<TechLookupRepository>()),
  );

  // Presentation - Dashboard Bloc
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      getWorkItemsUseCase: getIt<GetWorkItemsUseCase>(),
      updateWorkStatusUseCase: getIt<UpdateWorkStatusUseCase>(),
    ),
  );

  // Presentation - Lookup Blocs
  getIt.registerFactory<VehicleDetailBloc>(
    () => VehicleDetailBloc(
      searchVehicleByPlateUseCase: getIt<SearchVehicleByPlateUseCase>(),
      getVehicleWarrantiesUseCase: getIt<GetVehicleWarrantiesUseCase>(),
    ),
  );

  getIt.registerFactory<VehicleListBloc>(
    () => VehicleListBloc(
      getAllVehiclesUseCase: getIt<GetAllVehiclesUseCase>(),
    ),
  );

  getIt.registerFactory<PartsLookupBloc>(
    () => PartsLookupBloc(
      getInventoryPartsUseCase: getIt<GetInventoryPartsUseCase>(),
    ),
  );

  getIt.registerFactory<WorkOrderSearchBloc>(
    () => WorkOrderSearchBloc(
      searchWorkOrdersUseCase: getIt<SearchWorkOrdersUseCase>(),
    ),
  );

  // Chat
  getIt.registerLazySingleton<TechChatRemoteDataSource>(
    () => TechChatRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<TechChatRepository>(
    () => TechChatRepositoryImpl(
      remoteDataSource: getIt<TechChatRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<TechChatBloc>(
    () => TechChatBloc(repository: getIt<TechChatRepository>()),
  );
}

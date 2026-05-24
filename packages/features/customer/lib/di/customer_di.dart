import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../data/datasources/remote/customer_maintenance_log_remote_datasource.dart';
import '../data/datasources/remote/customer_vehicle_remote_datasource.dart';
import '../data/datasources/remote/customer_work_order_remote_datasource.dart';
import '../data/repositories/customer_repository_impl.dart';
import '../domain/repositories/customer_repository.dart';
import '../domain/usecases/get_customer_vehicles.dart';
import '../domain/usecases/get_vehicle_work_orders.dart';
import '../presentation/vehicles/bloc/customer_vehicle_bloc.dart';
import '../presentation/vehicles/bloc/customer_work_order_bloc.dart';

final getIt = GetIt.instance;

void setupCustomerDependencies() {
  // Data sources
  getIt.registerLazySingleton<CustomerVehicleRemoteDataSource>(
    () => CustomerVehicleRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<CustomerWorkOrderRemoteDataSource>(
    () => CustomerWorkOrderRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<CustomerMaintenanceLogRemoteDataSource>(
    () => CustomerMaintenanceLogRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  // Repository
  getIt.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(
      vehicleRemoteDataSource: getIt<CustomerVehicleRemoteDataSource>(),
      workOrderRemoteDataSource: getIt<CustomerWorkOrderRemoteDataSource>(),
      maintenanceLogRemoteDataSource: getIt<CustomerMaintenanceLogRemoteDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<GetCustomerVehicles>(
    () => GetCustomerVehicles(getIt<CustomerRepository>()),
  );

  getIt.registerLazySingleton<GetVehicleWorkOrders>(
    () => GetVehicleWorkOrders(getIt<CustomerRepository>()),
  );

  // Presentation blocs
  getIt.registerFactory<CustomerVehicleBloc>(
    () => CustomerVehicleBloc(getCustomerVehicles: getIt<GetCustomerVehicles>()),
  );

  getIt.registerFactory<CustomerWorkOrderBloc>(
    () => CustomerWorkOrderBloc(getVehicleWorkOrders: getIt<GetVehicleWorkOrders>()),
  );
}

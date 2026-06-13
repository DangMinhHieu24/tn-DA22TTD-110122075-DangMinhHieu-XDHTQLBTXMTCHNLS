import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';
import '../domain/repositories/admin_appointment_repository.dart';
import '../domain/repositories/dashboard_repository.dart';
import '../domain/repositories/revenue_report_repository.dart';
import '../domain/usecases/get_dashboard_stats.dart';
import '../domain/usecases/get_revenue_report.dart';
import '../domain/usecases/get_upcoming_appointments.dart';
import '../domain/usecases/delete_appointment.dart';
import '../presentation/dashboard/bloc/dashboard_bloc.dart';
import '../presentation/dashboard/bloc/revenue_report_bloc.dart';
import '../presentation/vehicle_intake/bloc/vehicle_intake_bloc.dart';
import '../presentation/vehicle_intake/bloc/admin_appointment_bloc.dart';
import '../presentation/dashboard/bloc/inventory_bloc.dart';
import '../data/repositories/admin_appointment_repository_impl.dart';
import '../data/repositories/dashboard_repository_impl.dart';
import '../data/repositories/revenue_report_repository_impl.dart';
import '../data/repositories/vehicle_intake_repository.dart';
import '../data/datasources/remote/admin_appointment_remote_datasource.dart';
import '../data/datasources/remote/dashboard_remote_datasource.dart';
import '../data/datasources/remote/revenue_report_remote_datasource.dart';
import '../data/datasources/remote/vehicle_remote_datasource.dart';
import '../data/datasources/remote/work_order_remote_datasource.dart';
import '../data/datasources/remote/inventory_remote_datasource.dart';
import '../data/datasources/remote/lookup_remote_datasource.dart';
import '../data/repositories/lookup_repository_impl.dart';
import '../data/repositories/inventory_repository_impl.dart';
import '../domain/repositories/lookup_repository.dart';
import '../domain/repositories/inventory_repository.dart';
import '../domain/usecases/search_lookup.dart';
import '../presentation/lookup/bloc/lookup_bloc.dart';

final getIt = GetIt.instance;

void setupAdminDependencies() {
  print('🔧 Setting up Admin dependencies...');
  
  // Services
  getIt.registerLazySingleton<ImageUploadService>(
    () => ImageUploadService(),
  );

  getIt.registerLazySingleton<QRScannerService>(
    () => QRScannerService(),
  );

  // Data sources
  // Dio should already be registered by auth feature
  getIt.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<VehicleRemoteDataSource>(
    () => VehicleRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<WorkOrderRemoteDataSource>(
    () => WorkOrderRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<InventoryRemoteDataSource>(
    () => InventoryRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<RevenueReportRemoteDataSource>(
    () => RevenueReportRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<LookupRemoteDataSource>(
    () => LookupRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  // Repository
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      remoteDataSource: getIt<DashboardRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<RevenueReportRepository>(
    () => RevenueReportRepositoryImpl(
      remoteDataSource: getIt<RevenueReportRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<LookupRepository>(
    () => LookupRepositoryImpl(
      remoteDataSource: getIt<LookupRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<VehicleIntakeRepository>(
    () => VehicleIntakeRepository(
      vehicleDataSource: getIt<VehicleRemoteDataSource>(),
      workOrderDataSource: getIt<WorkOrderRemoteDataSource>(),
      imageUploadService: getIt<ImageUploadService>(),
      dio: getIt<Dio>(),
    ),
  );

  // Appointment data source + repository
  getIt.registerLazySingleton<AdminAppointmentRemoteDataSource>(
    () => AdminAppointmentRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<AdminAppointmentRepository>(
    () => AdminAppointmentRepositoryImpl(
      remoteDataSource: getIt<AdminAppointmentRemoteDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<GetUpcomingAppointments>(
    () => GetUpcomingAppointments(getIt<AdminAppointmentRepository>()),
  );

  getIt.registerLazySingleton<DeleteAppointment>(
    () => DeleteAppointment(getIt<AdminAppointmentRepository>()),
  );

  getIt.registerLazySingleton<GetDashboardStats>(
    () => GetDashboardStats(getIt<DashboardRepository>()),
  );

  getIt.registerLazySingleton<GetRevenueReport>(
    () => GetRevenueReport(getIt<RevenueReportRepository>()),
  );

  getIt.registerLazySingleton<SearchLookupUseCase>(
    () => SearchLookupUseCase(getIt<LookupRepository>()),
  );

  // Presentation - Dashboard Bloc
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      getDashboardStats: getIt<GetDashboardStats>(),
    ),
  );

  getIt.registerFactory<RevenueReportBloc>(
    () => RevenueReportBloc(
      getRevenueReport: getIt<GetRevenueReport>(),
    ),
  );

  // Presentation - Vehicle Intake Bloc
  getIt.registerFactory<VehicleIntakeBloc>(
    () => VehicleIntakeBloc(
      repository: getIt<VehicleIntakeRepository>(),
      imageUploadService: getIt<ImageUploadService>(),
      qrScannerService: getIt<QRScannerService>(),
    ),
  );

  // Presentation - Admin Appointment Bloc
  print('📦 Registering AdminAppointmentBloc...');
  try {
    getIt.registerFactory<AdminAppointmentBloc>(
      () {
        print('  ↳ Factory called, getting GetUpcomingAppointments...');
        final useCase = getIt<GetUpcomingAppointments>();
        print('  ↳ Got useCase, creating AdminAppointmentBloc...');
        return AdminAppointmentBloc(
          getUpcomingAppointments: useCase,
        );
      },
    );
    print('✅ AdminAppointmentBloc registered successfully');
  } catch (e) {
    print('❌ Error registering AdminAppointmentBloc: $e');
    rethrow;
  }

  // Inventory Repository
  getIt.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(
      remoteDataSource: getIt<InventoryRemoteDataSource>(),
    ),
  );

  // Presentation - Inventory Bloc
  getIt.registerFactory<InventoryBloc>(
    () => InventoryBloc(
      repository: getIt<InventoryRepository>(),
    ),
  );

  // Presentation - Lookup Bloc
  getIt.registerFactory<LookupBloc>(
    () => LookupBloc(
      repository: getIt<LookupRepository>(),
      searchUseCase: getIt<SearchLookupUseCase>(),
    ),
  );
  
  print('✅ Admin dependencies setup completed!');
}

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';
import '../domain/repositories/dashboard_repository.dart';
import '../domain/repositories/revenue_report_repository.dart';
import '../domain/usecases/get_dashboard_stats.dart';
import '../domain/usecases/get_revenue_report.dart';
import '../presentation/dashboard/bloc/dashboard_bloc.dart';
import '../presentation/dashboard/bloc/revenue_report_bloc.dart';
import '../presentation/vehicle_intake/bloc/vehicle_intake_bloc.dart';
import '../presentation/dashboard/bloc/inventory_bloc.dart';
import '../data/repositories/dashboard_repository_impl.dart';
import '../data/repositories/revenue_report_repository_impl.dart';
import '../data/repositories/vehicle_intake_repository.dart';
import '../data/datasources/remote/dashboard_remote_datasource.dart';
import '../data/datasources/remote/revenue_report_remote_datasource.dart';
import '../data/datasources/remote/vehicle_remote_datasource.dart';
import '../data/datasources/remote/work_order_remote_datasource.dart';
import '../data/datasources/remote/inventory_remote_datasource.dart';

final getIt = GetIt.instance;

void setupAdminDependencies() {
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

  getIt.registerLazySingleton<VehicleIntakeRepository>(
    () => VehicleIntakeRepository(
      vehicleDataSource: getIt<VehicleRemoteDataSource>(),
      workOrderDataSource: getIt<WorkOrderRemoteDataSource>(),
      imageUploadService: getIt<ImageUploadService>(),
      dio: getIt<Dio>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<GetDashboardStats>(
    () => GetDashboardStats(getIt<DashboardRepository>()),
  );

  getIt.registerLazySingleton<GetRevenueReport>(
    () => GetRevenueReport(getIt<RevenueReportRepository>()),
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

  // Presentation - Inventory Bloc
  getIt.registerFactory<InventoryBloc>(
    () => InventoryBloc(
      dataSource: getIt<InventoryRemoteDataSource>(),
    ),
  );
}

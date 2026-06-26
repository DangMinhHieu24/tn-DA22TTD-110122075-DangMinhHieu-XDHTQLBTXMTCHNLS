import 'package:get_it/get_it.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';
import 'package:technician/technician.dart';
import 'package:admin/admin.dart';
import 'package:customer/customer.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Shared services
  getIt.registerLazySingleton<ImageUploadService>(
    () => ImageUploadService(),
  );

  // Setup auth dependencies first (provides Dio)
  setupAuthDependencies();
  
  // Setup admin dependencies (depends on Dio from auth)
  setupAdminDependencies();
  
  // Setup technician dependencies
  setupTechnicianDependencies();
  
  // Setup customer dependencies
  setupCustomerDependencies();
}

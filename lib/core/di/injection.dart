import 'package:get_it/get_it.dart';
import 'package:auth/auth.dart';
import 'package:technician/technician.dart';
import 'package:admin/admin.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Setup auth dependencies
  setupAuthDependencies();
  
  // Setup technician dependencies
  setupTechnicianDependencies();
  
  // Setup admin dependencies
  setupAdminDependencies();
  
  // TODO: Setup other feature dependencies
  // setupCustomerDependencies();
}

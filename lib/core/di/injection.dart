import 'package:get_it/get_it.dart';
import 'package:auth/auth.dart';
import 'package:technician/technician.dart';
import 'package:admin/admin.dart';
import 'package:customer/customer.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Setup auth dependencies
  setupAuthDependencies();
  
  // Setup technician dependencies
  setupTechnicianDependencies();
  
  // Setup admin dependencies
  setupAdminDependencies();
  
  // Setup customer dependencies
  setupCustomerDependencies();
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth/auth.dart';
import 'package:technician/technician.dart' as tech;
import 'package:admin/admin.dart' as admin;
import 'package:customer/customer.dart' as customer;
import 'package:get_it/get_it.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminWorkOrderList = '/admin/work-order-list';
  static const String adminVehicleIntake = '/admin/vehicle-intake';
  static const String adminRevenueReport = '/admin/revenue-report';
  static const String adminLookup = '/admin/lookup';
  static const String technicianDashboard = '/technician/dashboard';
  static const String technicianWorkList = '/technician/work-list';
  static const String customerDashboard = '/customer/dashboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => LoginBloc(
              loginUseCase: GetIt.instance<LoginUseCase>(),
              localDataSource: GetIt.instance<AuthLocalDataSource>(),
            ),
            child: const LoginPage(),
          ),
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => RegisterBloc(
              registerUseCase: GetIt.instance<RegisterUseCase>(),
            ),
            child: const RegisterPage(),
          ),
        );

      case technicianDashboard:
        return MaterialPageRoute(
          builder: (_) => const tech.TechnicianDashboardPage(),
        );

      case technicianWorkList:
        final args = settings.arguments;
        final items = (args is List) ? args.cast<tech.WorkItem>() : <tech.WorkItem>[];
        return MaterialPageRoute(
          builder: (_) => tech.TechnicianWorkListPage(workItems: items),
        );

      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const admin.AdminDashboardPage(),
        );

      case adminWorkOrderList:
        final model = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => admin.WorkOrderListPage(
            initialTabIndex: model['initialTabIndex'] as int? ?? 0,
          ),
        );

      case adminVehicleIntake:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => admin.VehicleIntakePage(
            initialLicensePlate: args['licensePlate'] as String?,
          ),
        );

      case adminRevenueReport:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => GetIt.instance<admin.RevenueReportBloc>(),
            child: const admin.AdminRevenueReportPage(),
          ),
        );

      case adminLookup:
        return MaterialPageRoute(
          builder: (_) => const admin.AdminLookupPage(),
        );

      case customerDashboard:
        return MaterialPageRoute(
          builder: (_) => const customer.MyVehiclesPage(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait a bit for splash effect
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authRepository = GetIt.instance<AuthRepository>();
    final result = await authRepository.getCurrentUser();

    if (!mounted) return;

    result.fold(
      // No user logged in
      (failure) => Navigator.of(context).pushReplacementNamed(AppRouter.login),
      // User logged in, navigate to appropriate dashboard
      (user) {
        final route = _getDashboardRoute(user.role);
        Navigator.of(context).pushReplacementNamed(route);
      },
    );
  }

  String _getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppRouter.adminDashboard;
      case UserRole.technician:
        return AppRouter.technicianDashboard;
      case UserRole.customer:
        return AppRouter.customerDashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4), // green-50
              Color(0xFFE0F2FE), // blue-50
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco,
                size: 80,
                color: Color(0xFF15803D),
              ),
              SizedBox(height: 24),
              Text(
                'Năng Lượng Sạch',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF166534),
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                color: Color(0xFF15803D),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

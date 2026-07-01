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
  static const String technicianLookup = '/technician/lookup';
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
        return MaterialPageRoute(
          builder: (_) => const tech.TechnicianWorkListPage(),
        );

      case technicianLookup:
        return MaterialPageRoute(
          builder: (_) => const tech.TechnicianLookupPage(),
        );

      case adminDashboard:
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) {
              final authState = context.read<AuthBloc>().state;
              final bloc = GetIt.instance<admin.NotificationBloc>();
              if (authState is AuthAuthenticated) {
                bloc.add(admin.LoadNotifications(userId: authState.user.id));
              }
              return bloc;
            },
            child: const admin.AdminDashboardPage(),
          ),
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
          builder: (_) => const customer.CustomerMainShell(),
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
      case UserRole.staff:
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
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF006E2F), // Brand green
              Color(0xFF004D20), // Dark green
            ],
          ),
        ),
        child: Stack(
          children: [
            // Center Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Logo Container
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            'assets/app_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Brand Name
                  const Text(
                    'NĂNG LƯỢNG SẠCH',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Subtitle
                  Text(
                    'Hệ thống quản lý bảo trì xe điện thông minh',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Spinner
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            
            // Version Footer
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'XANH EV • Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

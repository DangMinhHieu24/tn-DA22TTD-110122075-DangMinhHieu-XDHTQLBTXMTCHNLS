library admin;

// DI
export 'di/admin_di.dart';

// Domain
export 'domain/entities/dashboard_stats.dart';
export 'domain/entities/revenue_report.dart';
export 'domain/repositories/dashboard_repository.dart';
export 'domain/repositories/revenue_report_repository.dart';
export 'domain/usecases/get_dashboard_stats.dart';
export 'domain/usecases/get_revenue_report.dart';

// Data - Models
export 'data/models/dashboard_stats_model.dart';
export 'data/models/revenue_report_model.dart';
export 'data/models/vehicle_model.dart';
export 'data/models/work_order_model.dart';

// Data - DataSources
export 'data/datasources/remote/dashboard_remote_datasource.dart';
export 'data/datasources/remote/revenue_report_remote_datasource.dart';
export 'data/datasources/remote/vehicle_remote_datasource.dart';
export 'data/datasources/remote/work_order_remote_datasource.dart';

// Data - Repositories
export 'data/repositories/dashboard_repository_impl.dart';
export 'data/repositories/revenue_report_repository_impl.dart';
export 'data/repositories/vehicle_intake_repository.dart';

// Presentation - Dashboard
export 'presentation/dashboard/bloc/dashboard_bloc.dart';
export 'presentation/dashboard/bloc/dashboard_event.dart';
export 'presentation/dashboard/bloc/revenue_report_bloc.dart';
export 'presentation/dashboard/bloc/revenue_report_event.dart';
export 'presentation/dashboard/bloc/revenue_report_state.dart';
export 'presentation/dashboard/pages/admin_dashboard_page.dart';
export 'presentation/dashboard/pages/admin_revenue_report_page.dart';
export 'presentation/dashboard/pages/admin_alerts_page.dart';
export 'presentation/dashboard/widgets/stat_card.dart';
export 'presentation/dashboard/widgets/shortcut_button.dart';
export 'presentation/dashboard/widgets/alert_item.dart';
export 'presentation/dashboard/widgets/technician_item.dart';
export 'presentation/dashboard/widgets/bottom_nav_item.dart';

// Presentation - Vehicle Intake
export 'presentation/vehicle_intake/bloc/vehicle_intake_bloc.dart';
export 'presentation/vehicle_intake/pages/vehicle_intake_page.dart';
export 'presentation/vehicle_intake/widgets/service_checkbox.dart';

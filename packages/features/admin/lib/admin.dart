library admin;

// DI
export 'di/admin_di.dart';

// Domain
export 'domain/entities/admin_appointment.dart';
export 'domain/entities/dashboard_stats.dart';
export 'domain/entities/revenue_report.dart';
export 'domain/repositories/admin_appointment_repository.dart';
export 'domain/repositories/dashboard_repository.dart';
export 'domain/repositories/revenue_report_repository.dart';
export 'domain/repositories/notification_repository.dart';
export 'domain/usecases/get_dashboard_stats.dart';
export 'domain/usecases/get_revenue_report.dart';
export 'domain/usecases/get_upcoming_appointments.dart';

// Data - Models
export 'data/models/admin_appointment_model.dart';
export 'data/models/dashboard_stats_model.dart';
export 'data/models/revenue_report_model.dart';
export 'data/models/vehicle_model.dart';
export 'data/models/work_order_model.dart';
export 'data/models/notification_model.dart';

// Data - DataSources
export 'data/datasources/remote/admin_appointment_remote_datasource.dart';
export 'data/datasources/remote/dashboard_remote_datasource.dart';
export 'data/datasources/remote/revenue_report_remote_datasource.dart';
export 'data/datasources/remote/vehicle_remote_datasource.dart';
export 'data/datasources/remote/work_order_remote_datasource.dart';

// Data - Repositories
export 'data/repositories/admin_appointment_repository_impl.dart';
export 'data/repositories/dashboard_repository_impl.dart';
export 'data/repositories/revenue_report_repository_impl.dart';
export 'data/repositories/vehicle_intake_repository.dart';
export 'data/repositories/notification_repository_impl.dart';

// Presentation - Dashboard
export 'presentation/dashboard/bloc/dashboard_bloc.dart';
export 'presentation/dashboard/bloc/dashboard_event.dart';
export 'presentation/dashboard/bloc/revenue_report_bloc.dart';
export 'presentation/dashboard/bloc/revenue_report_event.dart';
export 'presentation/dashboard/bloc/revenue_report_state.dart';
export 'presentation/dashboard/pages/admin_dashboard_page.dart';
export 'presentation/dashboard/pages/work_order_list_page.dart';
export 'presentation/dashboard/pages/admin_revenue_report_page.dart';
export 'presentation/lookup/pages/admin_lookup_page.dart';
export 'presentation/lookup/pages/vehicle_lookup_page.dart';
export 'presentation/lookup/pages/customer_lookup_page.dart';
export 'presentation/lookup/pages/invoice_lookup_page.dart';
export 'presentation/lookup/widgets/radial_lookup_menu.dart';
export 'presentation/lookup/widgets/vehicle_search_result_card.dart';
export 'presentation/lookup/widgets/customer_search_result_card.dart';
export 'presentation/lookup/widgets/customer_detail_sheet.dart';
export 'presentation/lookup/widgets/technician_detail_sheet.dart';
export 'presentation/lookup/widgets/invoice_detail_sheet.dart';
export 'presentation/lookup/bloc/lookup_bloc.dart';
export 'presentation/lookup/bloc/lookup_state.dart';
export 'presentation/lookup/bloc/lookup_event.dart';
export 'presentation/dashboard/widgets/stat_card.dart';
export 'presentation/dashboard/widgets/shortcut_button.dart';
export 'presentation/dashboard/widgets/alert_item.dart';
export 'presentation/dashboard/widgets/technician_item.dart';
export 'presentation/dashboard/widgets/bottom_nav_item.dart';
export 'presentation/profile/bloc/notification_bloc.dart';
export 'presentation/profile/bloc/notification_event.dart';
export 'presentation/profile/bloc/notification_state.dart';
export 'presentation/profile/pages/notification_list_page.dart';

// Presentation - Vehicle Intake
export 'presentation/vehicle_intake/bloc/vehicle_intake_bloc.dart';
export 'presentation/vehicle_intake/bloc/admin_appointment_bloc.dart';
export 'presentation/vehicle_intake/bloc/admin_appointment_event.dart';
export 'presentation/vehicle_intake/bloc/admin_appointment_state.dart';
export 'presentation/vehicle_intake/pages/vehicle_intake_page.dart';
export 'presentation/vehicle_intake/pages/admin_add_vehicle_page.dart';
export 'presentation/vehicle_intake/pages/admin_create_customer_page.dart';
export 'presentation/vehicle_intake/widgets/service_checkbox.dart';

library technician;

// DI
export 'di/technician_di.dart';

// Domain - Entities
export 'domain/entities/work_item.dart';

// Domain - Repositories
export 'domain/repositories/work_repository.dart';

// Domain - UseCases
export 'domain/usecases/get_work_items_usecase.dart';
export 'domain/usecases/update_work_status_usecase.dart';
export 'domain/usecases/search_work_items_usecase.dart';

// Data - Models
export 'data/models/work_item_model.dart';

// Data - DataSources
export 'data/datasources/remote/work_remote_datasource.dart';
export 'data/datasources/local/work_local_datasource.dart';

// Data - Repositories
export 'data/repositories/work_repository_impl.dart';

// Presentation - Dashboard BLoC
export 'presentation/dashboard/bloc/dashboard_bloc.dart';
export 'presentation/dashboard/bloc/dashboard_event.dart';
export 'presentation/dashboard/bloc/dashboard_state.dart';

// Presentation - Dashboard Pages
export 'presentation/dashboard/pages/technician_dashboard_page.dart';

// Presentation - Settings Pages
export 'presentation/settings/pages/settings_page.dart';

// Presentation - Dashboard Widgets
export 'presentation/dashboard/widgets/dashboard_header.dart';
export 'presentation/dashboard/widgets/greeting_section.dart';
export 'presentation/dashboard/widgets/stats_card.dart';
export 'presentation/dashboard/widgets/urgent_work_card.dart';
export 'presentation/dashboard/widgets/work_card.dart';
export 'presentation/dashboard/widgets/draggable_fab.dart';
export 'presentation/dashboard/widgets/dashboard_bottom_nav.dart';

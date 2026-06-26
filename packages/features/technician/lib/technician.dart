library technician;

// DI
export 'di/technician_di.dart';

// Domain - Entities
export 'domain/entities/work_item.dart';
export 'domain/entities/tech_lookup_category.dart';
export 'domain/entities/vehicle_detail.dart';
export 'domain/entities/inventory_part.dart';

// Domain - Repositories
export 'domain/repositories/work_repository.dart';
export 'domain/repositories/tech_lookup_repository.dart';

// Domain - UseCases
export 'domain/usecases/get_work_items_usecase.dart';
export 'domain/usecases/update_work_status_usecase.dart';
export 'domain/usecases/search_vehicle_by_plate_usecase.dart';
export 'domain/usecases/get_vehicle_warranties_usecase.dart';
export 'domain/usecases/get_all_vehicles_usecase.dart';
export 'domain/usecases/get_inventory_parts_usecase.dart';
export 'domain/usecases/search_work_orders_usecase.dart';

// Data - Models
export 'data/models/work_item_model.dart';
export 'data/models/vehicle_detail_model.dart';
export 'data/models/inventory_part_model.dart';

// Data - DataSources
export 'data/datasources/remote/work_remote_datasource.dart';
export 'data/datasources/remote/tech_lookup_remote_datasource.dart';
export 'data/datasources/local/work_local_datasource.dart';

// Data - Repositories
export 'data/repositories/work_repository_impl.dart';
export 'data/repositories/tech_lookup_repository_impl.dart';

// Presentation - Dashboard BLoC
export 'presentation/dashboard/bloc/dashboard_bloc.dart';
export 'presentation/dashboard/bloc/dashboard_event.dart';
export 'presentation/dashboard/bloc/dashboard_state.dart';

// Presentation - Dashboard Pages
export 'presentation/dashboard/pages/technician_dashboard_page.dart';
export 'presentation/dashboard/pages/technician_work_list_page.dart';

// Presentation - Work Detail Pages
export 'presentation/work_detail/pages/work_detail_page.dart';

// Presentation - Settings Pages
export 'presentation/settings/pages/settings_page.dart';

// Presentation - Lookup
export 'presentation/lookup/pages/technician_lookup_page.dart';
export 'presentation/lookup/pages/vehicle_result_page.dart';
export 'presentation/lookup/pages/vehicle_list_page.dart';
export 'presentation/lookup/pages/parts_lookup_page.dart';
export 'presentation/lookup/widgets/technician_radial_menu.dart';
export 'presentation/lookup/bloc/vehicle_detail_bloc.dart';
export 'presentation/lookup/bloc/vehicle_detail_event.dart';
export 'presentation/lookup/bloc/vehicle_detail_state.dart';
export 'presentation/lookup/bloc/vehicle_list_bloc.dart';
export 'presentation/lookup/bloc/vehicle_list_event.dart';
export 'presentation/lookup/bloc/vehicle_list_state.dart';
export 'presentation/lookup/bloc/parts_lookup_bloc.dart';
export 'presentation/lookup/bloc/parts_lookup_event.dart';
export 'presentation/lookup/bloc/parts_lookup_state.dart';
export 'presentation/lookup/pages/tech_stats_page.dart';

// Presentation - Chat
export 'presentation/chat/bloc/tech_chat_bloc.dart';
export 'presentation/chat/bloc/tech_chat_event.dart';
export 'presentation/chat/bloc/tech_chat_state.dart';
export 'presentation/chat/widgets/tech_chat_floating_bubble.dart';

// Presentation - Dashboard Widgets
export 'presentation/dashboard/widgets/dashboard_header.dart';
export 'presentation/dashboard/widgets/greeting_section.dart';
export 'presentation/dashboard/widgets/stats_card.dart';
export 'presentation/dashboard/widgets/work_card.dart';
export 'presentation/dashboard/widgets/draggable_fab.dart';
export 'presentation/dashboard/widgets/dashboard_bottom_nav.dart';

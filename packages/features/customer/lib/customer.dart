library customer;

// DI
export 'di/customer_di.dart';

// Domain
export 'domain/entities/customer_vehicle.dart';
export 'domain/entities/customer_work_order.dart';
export 'domain/entities/customer_appointment.dart';
export 'domain/repositories/customer_repository.dart';
export 'domain/usecases/get_customer_vehicles.dart';
export 'domain/usecases/get_vehicle_work_orders.dart';
export 'domain/usecases/get_my_appointments.dart';
export 'domain/usecases/create_appointment.dart';
export 'domain/usecases/cancel_appointment.dart';

// Data
export 'data/models/customer_vehicle_model.dart';
export 'data/models/customer_work_order_model.dart';
export 'data/models/customer_appointment_model.dart';
export 'data/datasources/remote/customer_vehicle_remote_datasource.dart';
export 'data/datasources/remote/customer_work_order_remote_datasource.dart';
export 'data/datasources/remote/customer_appointment_remote_datasource.dart';
export 'data/repositories/customer_repository_impl.dart';

// Presentation - Vehicles Pages
export 'presentation/vehicles/pages/my_vehicles_page.dart';
export 'presentation/vehicles/pages/vehicle_detail_page.dart';
export 'presentation/vehicles/pages/customer_work_order_detail_page.dart';
export 'presentation/vehicles/pages/customer_main_shell.dart';

// Presentation - Warranty Pages
export 'presentation/warranties/pages/customer_warranty_page.dart';

// Presentation - Account Pages
export 'presentation/account/pages/customer_account_page.dart';
export 'presentation/account/pages/change_password_page.dart';
export 'presentation/notifications/pages/customer_notification_list_page.dart';

// Presentation - Appointment Pages
export 'presentation/appointments/pages/appointments_page.dart';
export 'presentation/appointments/pages/create_appointment_page.dart';

// Presentation - Customer Vehicles
export 'presentation/vehicles/bloc/customer_vehicle_bloc.dart';
export 'presentation/vehicles/widgets/customer_vehicle_card.dart';
export 'presentation/vehicles/widgets/customer_app_bar.dart';
export 'presentation/vehicles/widgets/customer_bottom_nav.dart';

// Presentation - Customer Work Orders
export 'presentation/vehicles/bloc/customer_work_order_bloc.dart';
export 'presentation/vehicles/widgets/customer_work_order_card.dart';

// Presentation - Appointments
export 'presentation/appointments/bloc/appointment_bloc.dart';
export 'presentation/appointments/widgets/appointment_card.dart';

// Presentation - Chat
export 'presentation/chat/bloc/chat_bloc.dart';
export 'presentation/chat/bloc/chat_event.dart';
export 'presentation/chat/bloc/chat_state.dart';
export 'presentation/chat/widgets/chat_floating_bubble.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import '../widgets/customer_app_bar.dart';
import '../widgets/customer_bottom_nav.dart';
import '../../account/pages/customer_account_page.dart';
import '../../appointments/pages/appointments_page.dart';
import '../bloc/customer_vehicle_bloc.dart';
import '../widgets/customer_vehicle_card.dart';
import 'vehicle_detail_page.dart';

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  late final CustomerVehicleBloc _vehicleBloc;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _vehicleBloc = GetIt.instance<CustomerVehicleBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && !_hasLoaded) {
        _hasLoaded = true;
        _vehicleBloc.add(LoadCustomerVehicles(ownerId: authState.user.id));
      }
    });
  }

  @override
  void dispose() {
    _vehicleBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _vehicleBloc,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              const CustomerAppBar(),
              Expanded(
                child: BlocListener<AuthBloc, AuthState>(
                  listenWhen: (previous, current) =>
                      previous.runtimeType != current.runtimeType,
                  listener: (context, state) {
                    if (state is AuthAuthenticated && !_hasLoaded) {
                      _hasLoaded = true;
                      _vehicleBloc.add(LoadCustomerVehicles(ownerId: state.user.id));
                    }
                    if (state is AuthUnauthenticated) {
                      _hasLoaded = false;
                    }
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xe của tôi',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        BlocBuilder<CustomerVehicleBloc, CustomerVehicleState>(
                          builder: (context, state) {
                            return _buildVehicleList(state);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              CustomerBottomNav(
                selectedIndex: 0,
                onItemSelected: (index) {
                  if (index == 1) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AppointmentsPage(),
                      ),
                    );
                  } else if (index == 3) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const CustomerAccountPage(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleList(CustomerVehicleState state) {
    if (state is CustomerVehicleLoading || state is CustomerVehicleInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CustomerVehicleError) {
      return Text(
        state.message,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
      );
    }

    final vehicles = state is CustomerVehicleLoaded ? state.vehicles : const [];
    if (vehicles.isEmpty) {
      return Text(
        'Chưa có xe nào được đăng ký',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return CustomerVehicleCard(
          vehicle: vehicle,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VehicleDetailPage(vehicle: vehicle),
              ),
            );
          },
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemCount: vehicles.length,
    );
  }
}

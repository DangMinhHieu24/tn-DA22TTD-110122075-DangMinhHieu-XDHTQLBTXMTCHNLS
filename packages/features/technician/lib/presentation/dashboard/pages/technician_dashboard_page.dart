import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:auth/auth.dart';
import 'package:get_it/get_it.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/stats_card.dart';
import '../widgets/urgent_work_card.dart';
import '../widgets/work_card.dart';
import '../widgets/draggable_fab.dart';
import '../widgets/dashboard_bottom_nav.dart';
import '../../../domain/entities/work_item.dart';
import '../../settings/pages/settings_page.dart';
import '../../work_detail/pages/work_detail_page.dart';

class TechnicianDashboardPage extends StatelessWidget {
  const TechnicianDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<DashboardBloc>()
        ..add(const LoadDashboardData()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<DashboardBloc>().add(SearchWorkItems(_searchController.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          // Get user name from auth state
          final userName = authState is AuthAuthenticated 
              ? authState.user.name 
              : 'Người dùng';

          return BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              return Stack(
                children: [
                  // Main content
                  Column(
                    children: [
                      // Fixed Header
                      DashboardHeader(
                        onNotificationTap: () {
                          // TODO: Handle notification tap
                        },
                      ),

                      // Scrollable content
                      Expanded(
                        child: _buildContent(state, userName),
                      ),
                    ],
                  ),

                  // Floating Action Button
                  DraggableFab(
                    onTap: () {
                      // TODO: Handle accept vehicle tap
                    },
                  ),

                  // Bottom Navigation
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: DashboardBottomNav(
                      selectedIndex: _selectedIndex,
                      onItemSelected: (index) {
                        if (index == 3) {
                          // Navigate to Settings page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        } else {
                          setState(() {
                            _selectedIndex = index;
                          });
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(DashboardState state, String userName) {
    if (state is DashboardLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is DashboardError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<DashboardBloc>().add(const LoadDashboardData());
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state is DashboardLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardBloc>().add(const RefreshDashboardData());
          // Wait for refresh to complete
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreetingSection(
                searchController: _searchController,
                userName: userName,
              ),
              const SizedBox(height: 32),
              _buildStatsCards(state),
              const SizedBox(height: 32),
              _buildWorkSection(state),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatsCards(DashboardLoaded state) {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            icon: Icons.pending_actions,
            count: state.pendingCount.toString().padLeft(2, '0'),
            label: 'Chờ xử lý',
            color: AppColors.onSurfaceVariant,
            backgroundColor: AppColors.surfaceContainerLow,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            icon: Icons.build,
            count: state.inProgressCount.toString().padLeft(2, '0'),
            label: 'Đang làm',
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerLowest,
            isHighlighted: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            icon: Icons.inventory_2,
            count: state.waitingPartsCount.toString().padLeft(2, '0'),
            label: 'Chờ phụ tùng',
            color: AppColors.onSurfaceVariant,
            backgroundColor: AppColors.surfaceContainerLow,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkSection(DashboardLoaded state) {
    final urgentItems = state.urgentWorkItems;
    final normalItems = state.normalWorkItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Công việc hôm nay',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all work items
              },
              child: Text(
                'Xem tất cả',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Urgent work items
        ...urgentItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: UrgentWorkCard(
            licensePlate: item.licensePlate,
            vehicleModel: item.vehicleModel,
            customerName: item.customerName,
            description: item.description,
            onStartRepair: () {
              _openWorkDetail(context, item);
            },
          ),
        )),
        
        // Normal work items
        ...normalItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: WorkCard(
            licensePlate: item.licensePlate,
            vehicleModel: item.vehicleModel,
            customerName: item.customerName,
            description: item.description,
            time: item.scheduledTime,
            status: _getStatusText(item.status),
            statusColor: _getStatusColor(item.status),
            isInProgress: item.status == WorkStatus.inProgress,
            onDetailTap: () {
              _openWorkDetail(context, item);
            },
          ),
        )),
      ],
    );
  }

  void _openWorkDetail(BuildContext context, WorkItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkDetailPage(workItem: item),
      ),
    );
  }

  String _getStatusText(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return 'Chờ xử lý';
      case WorkStatus.inProgress:
        return 'Đang thực hiện';
      case WorkStatus.waitingParts:
        return 'Chờ phụ tùng';
      case WorkStatus.completed:
        return 'Hoàn thành';
    }
  }

  Color _getStatusColor(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return AppColors.outlineVariant;
      case WorkStatus.inProgress:
        return AppColors.primary;
      case WorkStatus.waitingParts:
        return AppColors.tertiary;
      case WorkStatus.completed:
        return AppColors.secondary;
    }
  }
}

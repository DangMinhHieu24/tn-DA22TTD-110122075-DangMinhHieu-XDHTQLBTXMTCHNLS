import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:auth/auth.dart';
import 'package:get_it/get_it.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/stats_card.dart';
import '../widgets/work_card.dart';
import '../widgets/dashboard_bottom_nav.dart';
import '../../../domain/entities/work_item.dart';
import '../../../domain/entities/tech_lookup_category.dart';
import '../../../domain/usecases/get_work_items_usecase.dart';
import '../../settings/pages/settings_page.dart';
import '../../work_detail/pages/work_detail_page.dart';
import '../../lookup/widgets/technician_radial_menu.dart';
import '../../lookup/bloc/vehicle_list_bloc.dart';
import '../../lookup/bloc/parts_lookup_bloc.dart';
import '../../lookup/bloc/vehicle_detail_bloc.dart';
import '../../lookup/pages/vehicle_list_page.dart';
import '../../lookup/pages/parts_lookup_page.dart';
import '../../lookup/pages/vehicle_result_page.dart';
import '../../lookup/bloc/work_order_search_bloc.dart';
import '../../lookup/pages/work_order_search_page.dart';
import '../../chat/widgets/tech_chat_floating_bubble.dart';
import 'notification_list_page.dart';

class TechnicianDashboardPage extends StatelessWidget {
  const TechnicianDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<DashboardBloc>(),
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
  String? _technicianId;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _technicianId = authState.user.id;
        if (!_hasLoaded) {
          _hasLoaded = true;
          context.read<DashboardBloc>().add(
            LoadDashboardData(technicianId: _technicianId),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType,
        listener: (context, authState) {
          if (authState is AuthAuthenticated) {
            _technicianId = authState.user.id;
            if (!_hasLoaded) {
              _hasLoaded = true;
              context.read<DashboardBloc>().add(
                LoadDashboardData(technicianId: _technicianId),
              );
            }
          } else if (authState is AuthUnauthenticated) {
            _technicianId = null;
            _hasLoaded = false;
            context.read<DashboardBloc>().add(const ResetDashboardData());
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
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
                        if (_selectedIndex != 3)
                          DashboardHeader(
                            userInitials: userName.isNotEmpty ? userName[0].toUpperCase() : 'TA',
                            onNotificationTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationListPage(),
                                ),
                              ).then((_) {
                                // Refresh dashboard data when coming back
                                context.read<DashboardBloc>().add(const LoadDashboardData());
                              });
                            },
                          ),

                        // Scrollable content
                        Expanded(
                          child: _selectedIndex == 1
                              ? const _LookupView()
                              : _selectedIndex == 2
                                  ? const _StatsView()
                                  : _selectedIndex == 3
                                      ? const SettingsPage()
                                      : _buildContent(state, userName),
                        ),
                      ],
                    ),

                    // Chat Floating Bubble
                    const TechChatFloatingBubble(),

                    // Premium Floating Glassmorphic Bottom Navigation Bar
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: DashboardBottomNav(
                        selectedIndex: _selectedIndex,
                        onItemSelected: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(DashboardState state, String userName) {
    if (state is DashboardInitial) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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
                context.read<DashboardBloc>().add(
                  LoadDashboardData(technicianId: _technicianId),
                );
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state is DashboardLoaded) {
      return RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreetingSection(
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

  Future<void> _refreshDashboard() async {
    context.read<DashboardBloc>().add(
      RefreshDashboardData(technicianId: _technicianId),
    );

    await Future.delayed(const Duration(milliseconds: 500));
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
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
        Expanded(
          child: StatsCard(
            icon: Icons.inventory_2,
            count: state.inspectionCount.toString().padLeft(2, '0'),
            label: 'Kiểm tra',
            color: AppColors.onSurfaceVariant,
            backgroundColor: AppColors.surfaceContainerLow,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkSection(DashboardLoaded state) {
    final items = state.todayWorkItems;

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
                Navigator.pushNamed(
                  context,
                  '/technician/work-list',
                  arguments: state.workItems,
                );
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
        
        // Work items
        ...items.map((item) => Padding(
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

  Future<void> _openWorkDetail(BuildContext context, WorkItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkDetailPage(workItem: item),
      ),
    );

    if (!mounted) return;
    context.read<DashboardBloc>().add(
      RefreshDashboardData(technicianId: _technicianId),
    );
  }

  String _getStatusText(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return 'Chờ xử lý';
      case WorkStatus.inProgress:
        return 'Đang thực hiện';
      case WorkStatus.inspection:
        return 'Kiểm tra';
      case WorkStatus.completed:
        return 'Hoàn thành';
      case WorkStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Color _getStatusColor(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending:
        return AppColors.outlineVariant;
      case WorkStatus.inProgress:
        return AppColors.primary;
      case WorkStatus.inspection:
        return AppColors.tertiary;
      case WorkStatus.completed:
        return AppColors.secondary;
      case WorkStatus.cancelled:
        return const Color(0xFFBA1A1A);
    }
  }
}

class _StatsView extends StatefulWidget {
  const _StatsView();

  @override
  State<_StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<_StatsView> {
  List<WorkItem>? _items;
  bool _loading = true;
  String? _error;
  String _selectedPeriod = 'month'; // 'week', 'month', 'all'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final authState = GetIt.instance<AuthBloc>().state;
      String? userId;
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
      }
      final useCase = GetIt.instance<GetWorkItemsUseCase>();
      final result = await useCase(GetWorkItemsParams(technicianId: userId));
      result.fold(
        (failure) {
          if (mounted) setState(() { _error = 'Không thể tải dữ liệu'; _loading = false; });
        },
        (items) {
          if (mounted) setState(() { _items = items; _loading = false; });
        },
      );
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006E2F))),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    return _buildContent();
  }

  Widget _buildContent() {
    final items = _items!;
    final now = DateTime.now();

    // Filter items based on selected period
    final filteredItems = items.where((item) {
      if (_selectedPeriod == 'week') {
        final startOfWeek = now.subtract(const Duration(days: 7));
        return item.createdAt.isAfter(startOfWeek);
      } else if (_selectedPeriod == 'month') {
        final startOfMonth = DateTime(now.year, now.month, 1);
        return item.createdAt.isAfter(startOfMonth);
      }
      return true; // 'all'
    }).toList();

    final total = filteredItems.length;
    final completed = filteredItems.where((i) => i.status == WorkStatus.completed).length;
    final inProgress = filteredItems.where((i) => i.status == WorkStatus.inProgress).length;
    
    final revenue = filteredItems
        .where((i) => i.status == WorkStatus.completed)
        .fold<double>(0, (sum, i) => sum + i.services.fold<double>(0, (s, sv) => s + (sv.price ?? 0)));
        
    final recentItems = filteredItems.where((i) => i.status == WorkStatus.completed).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Service Type Breakdown
    int maintenanceCount = 0;
    int batteryCount = 0;
    int brakesTiresCount = 0;
    int otherCount = 0;

    for (var item in filteredItems) {
      if (item.status == WorkStatus.completed) {
        for (var service in item.services) {
          final st = service.serviceType.toUpperCase();
          if (st.contains('MAINTENANCE')) {
            maintenanceCount++;
          } else if (st.contains('BATTERY')) {
            batteryCount++;
          } else if (st.contains('BRAKE') || st.contains('TIRE')) {
            brakesTiresCount++;
          } else {
            otherCount++;
          }
        }
      }
    }
    final totalServices = maintenanceCount + batteryCount + brakesTiresCount + otherCount;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _buildPeriodFilter(),
          _buildStatRow(total, completed, inProgress),
          const SizedBox(height: 16),
          _buildRevenueCard(revenue),
          const SizedBox(height: 16),
          _buildEarningCard(revenue, total, completed),
          const SizedBox(height: 20),
          _buildWeeklyChart(),
          const SizedBox(height: 20),
          _buildServiceBreakdown(totalServices, maintenanceCount, batteryCount, brakesTiresCount, otherCount),
          const SizedBox(height: 24),
          if (recentItems.isNotEmpty) ...[
            _buildSectionTitle('Phiếu hoàn thành gần đây'),
            const SizedBox(height: 10),
            ...recentItems.take(5).map(_buildRecentItem),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodTab('week', 'Tuần này'),
          _buildPeriodTab('month', 'Tháng này'),
          _buildPeriodTab('all', 'Tất cả'),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF006E2F) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(int total, int completed, int inProgress) {
    return Row(
      children: [
        _statCard('Tổng việc', '$total', const Color(0xFF006E2F), Icons.work_history),
        const SizedBox(width: 10),
        _statCard('Hoàn tất', '$completed', const Color(0xFF16A34A), Icons.check_circle_outline),
        const SizedBox(width: 10),
        _statCard('Đang làm', '$inProgress', const Color(0xFF0058BE), Icons.build),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(double revenue) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF006E2F), Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF006E2F).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng doanh thu', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('${_formatNumber(revenue)}đ', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningCard(double totalRevenue, int total, int completed) {
    final personalShare = totalRevenue * 0.3;
    final completionRate = total > 0 ? (completed * 100 ~/ total) : 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phụ cấp đề xuất (30%)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatNumber(personalShare)}đ',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF006E2F)),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: const Color(0xFFE5E7EB),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completionRate%',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF006E2F)),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tỉ lệ hoàn thành đơn',
                  style: TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final List<int> dailyCounts = List.filled(7, 0);
    final List<String> dayLabels = List.filled(7, '');
    final now = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      dayLabels[i] = '${day.day}/${day.month}';
      dailyCounts[i] = _items!.where((item) =>
        item.status == WorkStatus.completed &&
        item.createdAt.year == day.year &&
        item.createdAt.month == day.month &&
        item.createdAt.day == day.day
      ).length;
    }

    final maxCount = dailyCounts.reduce((a, b) => a > b ? a : b);
    final double maxY = maxCount > 0 ? (maxCount + 1).toDouble() : 5.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đơn hoàn thành (7 ngày qua)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < 7) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dayLabels[idx],
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dailyCounts[i].toDouble(),
                        color: const Color(0xFF006E2F),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: const Color(0xFFF3F4F6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceBreakdown(int total, int maintenance, int battery, int brakes, int other) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân tích dịch vụ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressRow('Bảo dưỡng định kỳ', maintenance, total, const Color(0xFF006E2F)),
          const SizedBox(height: 12),
          _buildProgressRow('Kiểm tra pin/sạc', battery, total, const Color(0xFF0058BE)),
          const SizedBox(height: 12),
          _buildProgressRow('Phanh & Lốp', brakes, total, const Color(0xFFD97706)),
          const SizedBox(height: 12),
          _buildProgressRow('Sửa chữa khác', other, total, const Color(0xFF6B7280)),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF191C1E)),
            ),
            Text(
              '$count · ${(percentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF191C1E)));
  }

  Widget _buildRecentItem(WorkItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.check_circle, color: Color(0xFF006E2F), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.licensePlate, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF006E2F))),
                const SizedBox(height: 2),
                Text(item.customerName, style: const TextStyle(fontSize: 12, color: Color(0xFF191C1E))),
              ],
            ),
          ),
          Text(_formatDate(item.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';

  String _formatNumber(num value) {
    return NumberFormat('#,###', 'vi_VN').format(value);
  }
}

class _LookupView extends StatelessWidget {
  const _LookupView();

  static const _categories = [
    TechLookupCategory(
      id: 'vehicle',
      label: 'Danh sách xe',
      icon: Icons.directions_car,
      color: Color(0xFF006E2F),
      bgColor: Color(0xFFE8F5E9),
    ),
    TechLookupCategory(
      id: 'part',
      label: 'Tra cứu',
      icon: Icons.search_rounded,
      color: Color(0xFF7B1FA2),
      bgColor: Color(0xFFF3E5F5),
    ),
    TechLookupCategory(
      id: 'warranty',
      label: 'Bảo hành',
      icon: Icons.shield_outlined,
      color: Color(0xFF0058BE),
      bgColor: Color(0xFFE3F2FD),
    ),
    TechLookupCategory(
      id: 'work_order',
      label: 'Phiếu Sửa Chữa',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFFF7ED),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        child: TechnicianRadialMenu(
          categories: _categories,
          onCategorySelected: (category) {
            _handleCategorySelected(context, category);
          },
        ),
      ),
    );
  }

  void _handleCategorySelected(
      BuildContext context, TechLookupCategory category) {
    switch (category.id) {
      case 'vehicle':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => GetIt.instance<VehicleListBloc>(),
              child: const VehicleListPage(),
            ),
          ),
        );
      case 'part':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => GetIt.instance<PartsLookupBloc>(),
              child: const PartsLookupPage(),
            ),
          ),
        );
      case 'warranty':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => GetIt.instance<VehicleDetailBloc>(),
              child: const VehicleResultPage(initialMode: 'warranty'),
            ),
          ),
        );
      case 'work_order':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => GetIt.instance<WorkOrderSearchBloc>(),
              child: const WorkOrderSearchPage(),
            ),
          ),
        );
    }
  }
}

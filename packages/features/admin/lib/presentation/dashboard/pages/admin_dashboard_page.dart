import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:auth/presentation/bloc/auth_bloc.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../dashboard/bloc/dashboard_event.dart';
import '../../../data/repositories/vehicle_intake_repository.dart';
import '../../../data/models/technician_model.dart';
import '../../dashboard/bloc/dashboard_state.dart';
import '../../../domain/entities/dashboard_stats.dart';
import '../../vehicle_intake/pages/reception_hub_page.dart';
import 'inventory_page.dart';

/// Admin Dashboard - 100% converted from HTML design
/// Follows Material Design 3 color system and Tailwind spacing
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedNavIndex = 0;
  int _selectedRevenueBarIndex = -1;
  late final DashboardBloc _dashboardBloc;
  final VehicleIntakeRepository _vehicleIntakeRepository = GetIt.instance<VehicleIntakeRepository>();
  List<TechnicianModel> _technicians = [];
  bool _loadingTechnicians = false;
  String? _techniciansError;

  @override
  void initState() {
    super.initState();
    _dashboardBloc = GetIt.instance<DashboardBloc>();
    _dashboardBloc.add(LoadDashboardStats());
    // Try loading technicians immediately (will succeed if token already available)
    _loadTechnicians();
    // Defer loading technicians until auth state is available
  }

  Future<void> _loadTechnicians() async {
    try {
      setState(() {
        _loadingTechnicians = true;
        _techniciansError = null;
      });
      final list = await _vehicleIntakeRepository.getTechnicians();
      setState(() {
        _technicians = list;
        _loadingTechnicians = false;
      });
    } catch (e) {
      setState(() {
        _techniciansError = e.toString();
        _loadingTechnicians = false;
      });
    }
  }

  @override
  void dispose() {
    _dashboardBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dashboardBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
            return;
          }

          // When authenticated, load technicians (token available via AuthLocalDataSource)
          if (state is AuthAuthenticated) {
            // Avoid redundant reloads
            if (!_loadingTechnicians && _technicians.isEmpty && _techniciansError == null) {
              _loadTechnicians();
            }

            // Ensure dashboard stats are reloaded after authentication so API call includes token
            _dashboardBloc.add(LoadDashboardStats());
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            // Get user info from auth state
            final userName = authState is AuthAuthenticated ? authState.user.name : 'Admin';
            final userEmail = authState is AuthAuthenticated ? authState.user.email : '';
            final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

            return Scaffold(
              backgroundColor: const Color(0xFFF7F9FB), // surface
              body: SafeArea(
                child: Column(
                  children: [
                    // Only show dashboard header on HOME and PROFILE tabs
                    if (_selectedNavIndex == 0 || _selectedNavIndex == 3)
                      _buildTopAppBar(userInitial, userName),
                    Expanded(
                      child: _selectedNavIndex == 2
                        ? _buildVehicleIntakePage()
                        : _selectedNavIndex == 3 
                        ? _buildProfilePage(userName, userEmail, context)
                        : RefreshIndicator(
                            onRefresh: () async {
                              await Future.wait([
                                _loadTechnicians(),
                                Future(() => _dashboardBloc.add(LoadDashboardStats())),
                              ]);
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 96), // pb-24 (24*4=96)
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32), // pt-6 px-4 pb-8 (reduced from pt-20)
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPageHeader(),
                                    const SizedBox(height: 32), // mb-8
                                    BlocBuilder<DashboardBloc, DashboardState>(
                                      builder: (context, dashboardState) {
                                        return _buildQuickStatsGrid(dashboardState);
                                      },
                                    ),
                                    const SizedBox(height: 24), // space-y-6
                                    _buildMainContent(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: _buildBottomNavBar(),
            );
          },
        ),
      ),
    );
  }

  /// TopAppBar - Fixed header with backdrop blur
  Widget _buildTopAppBar(String userInitial, String userName) {
    return Container(
      height: 64, // h-16
      padding: const EdgeInsets.symmetric(horizontal: 24), // px-6
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB).withValues(alpha: 0.8), // bg-[#F7F9FB]/80
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo + Title
          Container(
            width: 32, // w-8
            height: 32, // h-8
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E), // bg-primary-container
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userInitial,
                style: const TextStyle(
                  color: Color(0xFF004B1E), // text-on-primary-container
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12), // gap-3
          Text(
            userName,
            style: const TextStyle(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.w800, // font-extrabold
              color: Color(0xFF006E2F), // text-[#006E2F]
              letterSpacing: -0.5, // tracking-tight
            ),
          ),
          const Spacer(),
          // Notification button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE6E8EA).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 22),
              color: const Color(0xFF006E2F),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  /// Page Header - Title and subtitle
  Widget _buildPageHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trang chủ Quản lý',
          style: TextStyle(
            fontSize: 24, // text-2xl
            fontWeight: FontWeight.w700, // font-bold
            color: Color(0xFF006E2F), // text-primary
            height: 1.2,
          ),
        ),
        SizedBox(height: 4), // mt-1
        Text(
          'Tổng quan hoạt động bảo dưỡng Năng Lượng Sạch',
          style: TextStyle(
            fontSize: 13, // text-sm
            color: Color(0xFF3D4A3D), // text-on-surface-variant
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Quick Stats Grid - 2 cols mobile, 3 cols desktop
  /// grid-cols-2 md:grid-cols-3 gap-4
  Widget _buildQuickStatsGrid(DashboardState state) {
    final vehiclesInService = _statValue(
      state,
      (value) => value.vehiclesInService,
    );
    final completedToday = _statValue(
      state,
      (value) => value.completedToday,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Xe đang sửa',
                    value: vehiclesInService,
                    icon: Icons.build_outlined,
                    iconColor: const Color(0xFF0058BE), // text-secondary
                    iconBgColor: const Color(0xFF2170E4).withValues(alpha: 0.2), // bg-secondary-container/20
                    glowColor: const Color(0xFF2170E4).withValues(alpha: 0.1), // bg-secondary-container/10
                  ),
                ),
                const SizedBox(width: 16), // gap-4
                Expanded(
                  child: _buildStatCard(
                    label: 'Hoàn thành hôm nay',
                    value: completedToday,
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF006E2F), // text-primary
                    iconBgColor: const Color(0xFF22C55E).withValues(alpha: 0.2), // bg-primary-container/20
                    glowColor: const Color(0xFF22C55E).withValues(alpha: 0.1), // bg-primary-container/10
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // gap-4
            // Revenue card - full width on mobile, 1/3 on desktop
            _buildRevenueCard(),
          ],
        );
      },
    );
  }

  String _statValue(DashboardState state, int Function(DashboardStats) selector) {
    if (state is DashboardLoaded) {
      return selector(state.stats).toString();
    }
    if (state is DashboardLoading) {
      return '...';
    }
    return '--';
  }

  /// Individual Stat Card
  /// bg-surface-container-lowest p-5 rounded-2xl shadow-[0_20px_40px_rgba(25,28,30,0.06)]
  /// h-32 relative overflow-hidden
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color glowColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18), // slightly larger radius
      child: Material(
        elevation: 10, // stronger lift
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFFFFFFF),
        shadowColor: Colors.black.withValues(alpha: 0.25),
        child: Container(
          height: 132,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF3F7F4),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFDAE4DC),
              width: 0.8,
            ),
          ),
          child: Stack(
          children: [
            // Glow effect - absolute -bottom-4 -right-4 w-24 h-24 blur-xl
            Positioned(
              bottom: -16,
              right: -16,
              child: Container(
                width: 96, // w-24
                height: 96, // h-24
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [glowColor, glowColor.withValues(alpha: 0)],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content with padding
            Padding(
              padding: const EdgeInsets.all(20), // p-5
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label and icon row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13, // text-sm
                            fontWeight: FontWeight.w500, // font-medium
                            color: Color(0xFF3D4A3D), // text-on-surface-variant
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: iconColor, size: 18),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Value
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                      height: 1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Revenue Card - col-span-2 md:col-span-1
  Widget _buildRevenueCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFFFFFFF),
        shadowColor: Colors.black.withValues(alpha: 0.25),
        child: Container(
          height: 132,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFFFF2F0),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFF0D7D1),
              width: 0.8,
            ),
          ),
        child: Stack(
          children: [
            // Glow effect
            Positioned(
              bottom: -16,
              right: -16,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF8B7C).withValues(alpha: 0.1),
                      const Color(0xFFFF8B7C).withValues(alpha: 0),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content with padding
            Padding(
              padding: const EdgeInsets.all(20), // p-5
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Doanh thu hôm nay',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3D4A3D),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8B7C).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9E4036).withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: Color(0xFF9E4036),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '8.5tr',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191C1E),
                          height: 1,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(width: 4),
                      Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Text(
                          'VND',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3D4A3D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Main Content - 2 column layout on desktop
  /// grid grid-cols-1 lg:grid-cols-3 gap-6
  Widget _buildMainContent() {
    return Column(
      children: [
        // Revenue Chart
        _buildRevenueChart(),
        const SizedBox(height: 24), // gap-6
        // Quick Shortcuts
        _buildQuickShortcuts(),
        const SizedBox(height: 24), // gap-6
        // Alerts Section
        _buildAlertsSection(),
        const SizedBox(height: 24), // gap-6
        // Technicians Section
        _buildTechniciansSection(),
      ],
    );
  }

  /// Revenue Chart with grid lines and Y-axis
  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF2F7F3),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDAE4DC),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Biểu đồ doanh thu (7 ngày)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/admin/revenue-report');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Chi tiết',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF006E2F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24), // mb-6
          // Chart - h-48
          SizedBox(
            height: 192, // h-48 (48*4=192)
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                final isLive = state is DashboardLoaded;
                final weekly = isLive
                    ? state.stats.weeklyRevenue
                    : <double>[8500000.0, 9500000.0, 4200000.0, 12000000.0, 7200000.0, 10300000.0, 7800000.0];
                return _buildBarChartWithGrid(weekly, isLive: isLive);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Bar Chart with Grid Lines and Y-axis labels
  Widget _buildBarChartWithGrid(List<double> weeklyRevenue, {bool isLive = false}) {
    final labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    // If no real data, fallback to sample values (VND)
    final data = weeklyRevenue.isNotEmpty
        ? weeklyRevenue
        : [4000000, 6000000, 3000000, 8000000, 5000000, 7500000, 5500000];

    // Ensure all values are doubles to avoid runtime type mismatch
    final values = data.map((e) => e.toDouble()).toList();
    final maxY = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0.0;

    // Compute fractions (0..1) for each bar using double values
    final fractions = values.map((v) => (maxY > 0 ? (v / maxY) : 0.0).clamp(0.0, 1.0)).toList();

    String _fmt(double v) {
      if (v <= 0) return '0tr';
      final tr = v / 1000000;
      // show integer millions as '2tr', otherwise one decimal '1.8tr'
      final text = (tr % 1 == 0) ? tr.toInt().toString() : tr.toStringAsFixed(1);
      return '${text}tr';
    }

    String _tooltipValue(double value) {
      if (value <= 0) return '0đ';
      final formatter = NumberFormat('#,###', 'vi_VN');
      if (value >= 1000000) {
        final millionValue = value / 1000000;
        final text = millionValue % 1 == 0 ? millionValue.toStringAsFixed(0) : millionValue.toStringAsFixed(1);
        return '${text.replaceAll('.', ',')}tr';
      }
      return '${formatter.format(value).replaceAll(',', '.')}đ';
    }

    final yTicks = List.generate(4, (i) => maxY * (3 - i) / 3);

    return Stack(
      children: [
        // Demo/live indicator
        if (!isLive)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Dữ liệu demo',
                style: TextStyle(fontSize: 11, color: Color(0xFF3D4A3D)),
              ),
            ),
          ),
        // Y-axis labels - absolute left-0 top-0 h-full pb-6 pr-2
        Positioned(
          left: 0,
          top: 0,
          bottom: 24, // pb-6
          child: Container(
            width: 44, // increased width to avoid wrapping
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: yTicks.map((t) => Text(
                _fmt(t),
                style: const TextStyle(fontSize: 11, color: Color(0xFF3D4A3D)),
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )).toList(),
            ),
          ),
        ),
        // Chart area - pl-8
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 24), // pl-8 pb-6
          child: Stack(
            children: [
              // Grid lines - border-b border-surface-container-high/50
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) => Container(
                    height: 1,
                    color: const Color(0xFFE6E8EA).withValues(alpha: 0.5),
                  )),
                ),
              ),
              // Bars - w-2 (8px width) - items-end to align to bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end, // Align all bars to bottom
                children: List.generate(7, (index) {
                  final heightFraction = fractions.length > index ? fractions[index] : 0.0;
                  final value = values.length > index ? values[index] : 0.0;
                  final isSelected = _selectedRevenueBarIndex == index && value > 0;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _selectedRevenueBarIndex = index;
                        });
                      },
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: 32,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            clipBehavior: Clip.none,
                            children: [
                              if (isSelected)
                                Positioned(
                                  top: -38,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF191C1E),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.18),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _tooltipValue(value),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              Container(
                                width: 8, // w-2 - exact 8px like HTML
                                height: 168 * heightFraction, // 168 = chart height minus padding
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: isSelected
                                        ? [
                                            const Color(0x66006E2F),
                                            const Color(0xFF006E2F),
                                          ]
                                        : [
                                            const Color(0x33006E2F),
                                            const Color(0xFF006E2F),
                                          ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        // X-axis labels - absolute bottom-0 left-8 right-0 pt-2
        Positioned(
          bottom: 0,
          left: 32,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: labels.map((label) => Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF3D4A3D)),
            )).toList(),
          ),
        ),
      ],
    );
  }

  /// Quick Shortcuts - grid grid-cols-4 gap-4
  Widget _buildQuickShortcuts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lối tắt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191C1E),
          ),
        ),
        const SizedBox(height: 16), // mb-4
        Row(
          children: [
            _buildShortcutButton(
              icon: Icons.bar_chart,
              label: 'Xem\nbáo cáo',
              color: const Color(0xFF006E2F),
              onTap: () {},
            ),
            const SizedBox(width: 16), // gap-4
            _buildShortcutButton(
              icon: Icons.inventory_2,
              label: 'Quản lý\nkho',
              color: const Color(0xFF0058BE),
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, animation, __) => const InventoryPage(),
                    transitionsBuilder: (_, animation, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                );
              },
            ),
            const SizedBox(width: 16), // gap-4
            _buildShortcutButton(
              icon: Icons.verified,
              label: 'Bảo\nhành',
              color: const Color(0xFF4AE176),
              onTap: () {},
            ),
            const SizedBox(width: 16), // gap-4
            _buildShortcutButton(
              icon: Icons.settings,
              label: 'Cài\nđặt',
              color: const Color(0xFF3D4A3D),
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  /// Shortcut Button
  /// flex flex-col items-center gap-2 p-4 rounded-2xl bg-surface-container-low
  Widget _buildShortcutButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16), // p-4
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF2F4F6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE0E5EA),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF191C1E).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48, // w-12
                height: 48, // h-12
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8), // gap-2
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191C1E),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Alerts Section
  /// bg-surface-container-lowest p-5 rounded-2xl border border-outline-variant/15
  /// relative overflow-hidden
  Widget _buildAlertsSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFFF0ED),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFECC5BC),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBA1A1A).withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: const Color(0xFF191C1E).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -12,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF8B7C).withValues(alpha: 0.14),
                      const Color(0xFFFF8B7C).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFBA1A1A),
                        Color(0xFFFF8B7C),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAD6).withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFBA1A1A).withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cảnh báo hệ thống',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF191C1E),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tổng hợp các mục cần theo dõi ngay hôm nay',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5E6B5F),
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Xem tất cả',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF006E2F),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildAlertChip('3 cảnh báo', const Color(0xFFBA1A1A), const Color(0xFFFFDAD6).withValues(alpha: 0.95)),
                            _buildAlertChip('1 cần xử lý ngay', const Color(0xFF9E4036), const Color(0xFFFFE5E1).withValues(alpha: 0.96)),
                            _buildAlertChip('1 mức trung bình', const Color(0xFF6D7B6C), const Color(0xFFF2F4F6)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAlertItem(
                          Icons.inventory,
                          'Phụ tùng sắp hết',
                          'Má phanh trước (Còn 2 bộ)',
                          const Color(0xFFBA1A1A),
                          const Color(0xFFFFDAD6).withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        _buildAlertItem(
                          Icons.schedule,
                          'Xe trễ hẹn',
                          'Biển số: 30G-789.01 (Trễ 2 giờ)',
                          const Color(0xFF9E4036),
                          const Color(0xFFFF8B7C).withValues(alpha: 0.18),
                        ),
                        const SizedBox(height: 12),
                        _buildAlertItem(
                          Icons.history,
                          'Bảo hành sắp hết hạn',
                          '3 xe trong tuần này',
                          const Color(0xFF6D7B6C),
                          const Color(0xFFF2F4F6).withValues(alpha: 0.96),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Alert Item
  /// flex items-start gap-3 p-3 rounded-xl
  Widget _buildAlertItem(IconData icon, String title, String subtitle, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12), // gap-3
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191C1E),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4F5B50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertChip(String label, Color textColor, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  /// Technicians Section
  Widget _buildTechniciansSection() {
    return Container(
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.08),
            blurRadius: 50,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kỹ thuật viên',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Color(0xFF3D4A3D)),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16), // mb-4
          // Technician items - dynamic
          if (_loadingTechnicians)
            const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          if (!_loadingTechnicians && _technicians.isEmpty)
            Column(
              children: [
                Text(_techniciansError == null ? 'Không có kỹ thuật viên' : 'Lỗi tải: $_techniciansError'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await _loadTechnicians();
                  },
                  child: const Text('Tải lại'),
                ),
              ],
            ),
          if (!_loadingTechnicians)
            ..._technicians.map((t) {
              final initials = t.name.isNotEmpty ? t.name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join() : 'K';
              final badgeColor = t.isOnline ? const Color(0xFF006E2F) : const Color(0xFF3D4A3D);
              return Column(
                children: [
                  _buildTechnicianItem(initials, t.name, 'Kỹ thuật viên', t.vehicleCount, t.isOnline, badgeColor),
                  const SizedBox(height: 16),
                ],
              );
            }),
          const SizedBox(height: 16), // mt-4
          // View all button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8), // py-2
                side: BorderSide(
                  color: const Color(0xFFBCCBB9).withValues(alpha: 0.3),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // rounded-lg
                ),
              ),
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 13, // text-sm
                  fontWeight: FontWeight.w500, // font-medium
                  color: Color(0xFF006E2F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Technician Item
  /// flex items-center justify-between
  Widget _buildTechnicianItem(String initials, String name, String role, int vehicleCount, bool isOnline, Color badgeColor) {
    return Row(
      children: [
        // Avatar with status indicator
        Stack(
          children: [
            Container(
              width: 40, // w-10
              height: 40, // h-10
              decoration: const BoxDecoration(
                color: Color(0xFFE6E8EA), // bg-surface-container-high
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700, // font-bold
                    fontSize: 13,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ),
            ),
            // Status dot - absolute bottom-0 right-0 w-3 h-3
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12, // w-3
                height: 12, // h-3
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFF6BFF8F) : const Color(0xFFE0E3E5), // bg-primary-fixed : bg-surface-variant
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12), // gap-3
        // Name and role
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13, // text-sm
                  fontWeight: FontWeight.w600, // font-semibold
                  color: Color(0xFF191C1E),
                ),
              ),
              Text(
                role,
                style: const TextStyle(
                  fontSize: 11, // text-xs
                  color: Color(0xFF3D4A3D),
                ),
              ),
            ],
          ),
        ),
        // Vehicle count badge
        if (vehicleCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // px-3 py-1
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F6), // bg-surface-container-low
              borderRadius: BorderRadius.circular(9999), // rounded-full
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.two_wheeler, size: 14, color: badgeColor),
                const SizedBox(width: 4), // gap-1
                Text(
                  '$vehicleCount xe',
                  style: const TextStyle(
                    fontSize: 11, // text-xs
                    fontWeight: FontWeight.w600, // font-semibold
                    color: Color(0xFF191C1E),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Bottom Navigation Bar
  /// fixed bottom-0 left-0 w-full z-50 h-20 px-4 pb-safe
  /// bg-[#FFFFFF]/90 backdrop-blur-lg rounded-t-2xl shadow-[0_-10px_30px_rgba(0,0,0,0.04)]
  Widget _buildBottomNavBar() {
    return Container(
      height: 80, // h-20
      padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.9), // bg-[#FFFFFF]/90
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), // rounded-t-2xl
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'HOME', 0),
            _buildNavItem(Icons.bolt, 'ALERTS', 1),
            _buildNavItem(Icons.two_wheeler, 'TIẾP NHẬN XE', 2),
            _buildNavItem(Icons.person, 'PROFILE', 3),
          ],
        ),
      ),
    );
  }

  /// Navigation Item
  /// flex flex-col items-center justify-center px-4 py-1 rounded-xl
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // px-4 py-1
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12), // rounded-xl
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF006E2F) : const Color(0xFF3D4A3D),
              size: 24,
            ),
            const SizedBox(height: 4), // mt-1
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // text-[10px]
                fontWeight: FontWeight.w700, // font-bold
                color: isSelected ? const Color(0xFF006E2F) : const Color(0xFF3D4A3D),
                letterSpacing: 0.5, // tracking-wider
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reception Hub - gateway tr╞░ß╗¢c khi tiß║┐p nhß║¡n xe mß╗¢i
  Widget _buildVehicleIntakePage() {
    return const ReceptionHubPage();
  }

  /// Profile Page - Simple profile with logout button
  Widget _buildProfilePage(String userName, String userEmail, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Color(0xFF004B1E),
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Name
          Text(
            userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 8),
          // Email
          Text(
            userEmail,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF3D4A3D),
            ),
          ),
          const SizedBox(height: 8),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Admin',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006E2F),
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

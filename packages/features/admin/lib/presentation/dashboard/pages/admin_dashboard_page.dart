import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth/presentation/bloc/auth_bloc.dart';
import '../../vehicle_intake/pages/vehicle_intake_page.dart';

/// Admin Dashboard - 100% converted from HTML design
/// Follows Material Design 3 color system and Tailwind spacing
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
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
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 96), // pb-24 (24*4=96)
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32), // pt-6 px-4 pb-8 (reduced from pt-20)
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPageHeader(),
                                const SizedBox(height: 32), // mb-8
                                _buildQuickStatsGrid(),
                                const SizedBox(height: 24), // space-y-6
                                _buildMainContent(),
                              ],
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
    );
  }

  /// TopAppBar - Fixed header with backdrop blur
  Widget _buildTopAppBar(String userInitial, String userName) {
    return Container(
      height: 64, // h-16
      padding: const EdgeInsets.symmetric(horizontal: 24), // px-6
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB).withOpacity(0.8), // bg-[#F7F9FB]/80
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.06),
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
              color: const Color(0xFFE6E8EA).withOpacity(0.5),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
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
  Widget _buildQuickStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Xe đang sửa',
                    value: '18',
                    icon: Icons.build_outlined,
                    iconColor: const Color(0xFF0058BE), // text-secondary
                    iconBgColor: const Color(0xFF2170E4).withOpacity(0.2), // bg-secondary-container/20
                    glowColor: const Color(0xFF2170E4).withOpacity(0.1), // bg-secondary-container/10
                  ),
                ),
                const SizedBox(width: 16), // gap-4
                Expanded(
                  child: _buildStatCard(
                    label: 'Hoàn thành hôm nay',
                    value: '24',
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF006E2F), // text-primary
                    iconBgColor: const Color(0xFF22C55E).withOpacity(0.2), // bg-primary-container/20
                    glowColor: const Color(0xFF22C55E).withOpacity(0.1), // bg-primary-container/10
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
      borderRadius: BorderRadius.circular(16), // rounded-2xl - clip first
      child: Material(
        elevation: 8, // Material elevation for strong shadow
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFFFFFFF),
        shadowColor: Colors.black.withOpacity(0.3),
        child: Container(
          height: 128, // h-32
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF), // bg-surface-container-lowest
            borderRadius: BorderRadius.circular(16), // rounded-2xl
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
                    colors: [glowColor, glowColor.withOpacity(0)],
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
                        width: 32, // w-8
                        height: 32, // h-8
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 13), // text-sm
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Value
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 36, // text-3xl
                      fontWeight: FontWeight.w800, // font-extrabold
                      color: iconColor,
                      height: 1,
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
      borderRadius: BorderRadius.circular(16), // rounded-2xl - clip first
      child: Material(
        elevation: 8, // Material elevation for strong shadow
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFFFFFFF),
        shadowColor: Colors.black.withOpacity(0.3),
        child: Container(
          height: 128, // h-32
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF), // bg-surface-container-lowest
            borderRadius: BorderRadius.circular(16), // rounded-2xl
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
                      const Color(0xFFFF8B7C).withOpacity(0.1),
                      const Color(0xFFFF8B7C).withOpacity(0),
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8B7C).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: Color(0xFF9E4036), // text-tertiary
                          size: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        '8.5M',
                        style: TextStyle(
                          fontSize: 28, // text-2xl md:text-3xl
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191C1E), // text-on-background
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 4),
                      Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Text(
                          'VNĐ',
                          style: TextStyle(
                            fontSize: 16, // text-lg
                            fontWeight: FontWeight.w600, // font-semibold
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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.08),
            blurRadius: 50,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.04),
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
                'Biểu đồ doanh thu (7 ngày)',
                style: TextStyle(
                  fontSize: 16, // text-lg
                  fontWeight: FontWeight.w700, // font-bold
                  color: Color(0xFF191C1E),
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
                  'Chi tiết',
                  style: TextStyle(
                    fontSize: 13, // text-sm
                    fontWeight: FontWeight.w500, // font-medium
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
            child: _buildBarChartWithGrid(),
          ),
        ],
      ),
    );
  }

  /// Bar Chart with Grid Lines and Y-axis labels
  Widget _buildBarChartWithGrid() {
    // Data: h-[40%], h-[60%], h-[30%], h-[80%], h-[50%], h-[75%], h-[55%]
    final dataHeights = [0.40, 0.60, 0.30, 0.80, 0.50, 0.75, 0.55];
    final labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    
    return Stack(
      children: [
        // Y-axis labels - absolute left-0 top-0 h-full pb-6 pr-2
        Positioned(
          left: 0,
          top: 0,
          bottom: 24, // pb-6
          child: Container(
            width: 32, // pr-2 + space for text
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text('15M', style: TextStyle(fontSize: 11, color: Color(0xFF3D4A3D))),
                Text('10M', style: TextStyle(fontSize: 11, color: Color(0xFF3D4A3D))),
                Text('5M', style: TextStyle(fontSize: 11, color: Color(0xFF3D4A3D))),
                Text('0', style: TextStyle(fontSize: 11, color: Color(0xFF3D4A3D))),
              ],
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
                    color: const Color(0xFFE6E8EA).withOpacity(0.5),
                  )),
                ),
              ),
              // Bars - w-2 (8px width) - items-end to align to bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end, // Align all bars to bottom
                children: List.generate(7, (index) {
                  final height = dataHeights[index];
                  return Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 8, // w-2 - exact 8px like HTML
                        height: 168 * height, // 168 = chart height minus padding
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0x33006E2F), // from-primary/20
                              Color(0xFF006E2F), // to-primary
                            ],
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4), // rounded-t-full but smaller radius
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
            _buildShortcutButton(Icons.bar_chart, 'Xem\nbáo cáo', const Color(0xFF006E2F)),
            const SizedBox(width: 16), // gap-4
            _buildShortcutButton(Icons.inventory_2, 'Quản lý\nkho', const Color(0xFF0058BE)),
            const SizedBox(width: 16), // gap-4
            _buildShortcutButton(Icons.verified, 'Bảo\nhành', const Color(0xFF4AE176)),
            const SizedBox(width: 16), // gap-4
            _buildShortcutButton(Icons.settings, 'Cài\nđặt', const Color(0xFF3D4A3D)),
          ],
        ),
      ],
    );
  }

  /// Shortcut Button
  /// flex flex-col items-center gap-2 p-4 rounded-2xl bg-surface-container-low
  Widget _buildShortcutButton(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16), // p-4
        decoration: BoxDecoration(
          color: const Color(0xFFECEEF0), // bg-surface-container (darker gray)
          borderRadius: BorderRadius.circular(16), // rounded-2xl
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48, // w-12
              height: 48, // h-12
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF), // bg-surface-container-lowest
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000), // shadow-sm (stronger)
                    blurRadius: 4,
                    offset: Offset(0, 2),
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
                fontSize: 11, // text-xs
                fontWeight: FontWeight.w500, // font-medium
                color: Color(0xFF191C1E),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Alerts Section
  /// bg-surface-container-lowest p-5 rounded-2xl border border-outline-variant/15
  /// relative overflow-hidden
  Widget _buildAlertsSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFBCCBB9).withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191C1E).withOpacity(0.08),
              blurRadius: 50,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF191C1E).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Red bar on left - w-1 (4px)
            Container(
              width: 4,
              color: const Color(0xFFBA1A1A), // bg-error
            ),
            // Content with padding
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20), // p-5
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: const [
                        Icon(Icons.warning, color: Color(0xFFBA1A1A), size: 20),
                        SizedBox(width: 8), // gap-2
                        Text(
                          'Cảnh báo hệ thống',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // mb-4
                    // Alert items - space-y-3
                    _buildAlertItem(
                      Icons.inventory,
                      'Phụ tùng sắp hết',
                      'Má phanh trước (Còn 2 bộ)',
                      const Color(0xFFBA1A1A),
                      const Color(0xFFFFDAD6).withOpacity(0.4), // error-container/20 - lighter red
                    ),
                    const SizedBox(height: 12),
                    _buildAlertItem(
                      Icons.schedule,
                      'Xe trễ hẹn',
                      'Biển số: 30G-789.01 (Trễ 2 giờ)',
                      const Color(0xFF9E4036),
                      const Color(0xFFFF8B7C).withOpacity(0.2), // tertiary-container/20 - darker pink/red
                    ),
                    const SizedBox(height: 12),
                    _buildAlertItem(
                      Icons.history,
                      'Bảo hành sắp hết hạn',
                      '3 xe trong tuần này',
                      const Color(0xFF6D7B6C),
                      const Color(0xFFF2F4F6), // surface-container-low - lighter gray
                    ),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.all(12), // p-3
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12), // rounded-xl
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor.withOpacity(0.7), size: 20), // slightly transparent, larger
          const SizedBox(width: 12), // gap-3
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14, // text-sm (larger)
                    fontWeight: FontWeight.w600, // font-semibold
                    color: Color(0xFF191C1E),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12, // text-xs (larger)
                    color: Color(0xFF6D7B6C),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            color: const Color(0xFF191C1E).withOpacity(0.08),
            blurRadius: 50,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.04),
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
          // Technician items - space-y-4
          _buildTechnicianItem('TA', 'Tuấn Anh', 'Trưởng nhóm', 4, true, const Color(0xFF006E2F)),
          const SizedBox(height: 16),
          _buildTechnicianItem('MĐ', 'Minh Đức', 'Chuyên viên điện', 2, true, const Color(0xFF0058BE)),
          const SizedBox(height: 16),
          _buildTechnicianItem('HQ', 'Hoàng Quân', 'Thực tập sinh', 0, false, const Color(0xFF3D4A3D)),
          const SizedBox(height: 16), // mt-4
          // View all button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8), // py-2
                side: BorderSide(
                  color: const Color(0xFFBCCBB9).withOpacity(0.3),
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
        color: const Color(0xFFFFFFFF).withOpacity(0.9), // bg-[#FFFFFF]/90
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), // rounded-t-2xl
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            _buildNavItem(Icons.two_wheeler, 'TIẾP NHẬN', 2),
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
          color: isSelected ? const Color(0xFF22C55E).withOpacity(0.1) : Colors.transparent,
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

  /// Vehicle Intake Page wrapper
  Widget _buildVehicleIntakePage() {
    return VehicleIntakePage();
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
              color: const Color(0xFF22C55E).withOpacity(0.2),
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

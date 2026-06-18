import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth/auth.dart';
import '../../vehicles/widgets/customer_bottom_nav.dart';
import '../../vehicles/pages/my_vehicles_page.dart';
import '../../appointments/pages/appointments_page.dart';

class CustomerAccountPage extends StatelessWidget {
  const CustomerAccountPage({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

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
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Profile Header ──
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 28),
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF006E2F),
                                  Color(0xFF059669),
                                ],
                              ),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(28),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  child: Text(
                                    user != null ? _initials(user.name) : '??',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.name ?? 'Khách hàng',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.email ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                      if (user != null && user.phoneNumber != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            user.phoneNumber!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withValues(alpha: 0.75),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Trees Impact (hero) ──
                          if (user != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF1B5E20),
                                      Color(0xFF2E7D32),
                                      Color(0xFF388E3C),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Big tree number
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ...List.generate(
                                          user.treesPlanted > 3 ? 3 : user.treesPlanted,
                                          (i) => Padding(
                                            padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                                            child: Icon(
                                              Icons.forest,
                                              size: 32,
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ),
                                        if (user.treesPlanted > 3)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4),
                                            child: Text(
                                              '+${user.treesPlanted - 3}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${user.treesPlanted}',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.treesPlanted > 1 ? 'Cây đã được trồng' : 'Cây đã được trồng',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Nhờ những lần sửa chữa của bạn',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withValues(alpha: 0.65),
                                      ),
                                    ),

                                    // Points as secondary info
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.card_giftcard,
                                            size: 16,
                                            color: Colors.white.withValues(alpha: 0.9),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${user.loyaltyPoints} điểm tích luỹ',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.chevron_right,
                                            size: 16,
                                            color: Colors.white.withValues(alpha: 0.6),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── Menu Items ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildMenuItem(
                                    icon: Icons.assignment_outlined,
                                    label: 'Lịch sử sửa chữa',
                                    onTap: () {},
                                  ),
                                  _buildDivider(),
                                  _buildMenuItem(
                                    icon: Icons.calendar_month_outlined,
                                    label: 'Lịch hẹn của tôi',
                                    onTap: () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) => const AppointmentsPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDivider(),
                                  _buildMenuItem(
                                    icon: Icons.support_agent_outlined,
                                    label: 'Hỗ trợ',
                                    onTap: () {},
                                  ),
                                  _buildDivider(),
                                  _buildMenuItem(
                                    icon: Icons.info_outline,
                                    label: 'Điều khoản sử dụng',
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Logout ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text('Đăng xuất'),
                                      content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Huỷ'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            context.read<AuthBloc>().add(const AuthLogoutRequested());
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFDC2626),
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Đăng xuất'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.logout, size: 20, color: Color(0xFFDC2626)),
                                label: const Text(
                                  'Đăng xuất',
                                  style: TextStyle(color: Color(0xFFDC2626)),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CustomerBottomNav(
                    selectedIndex: 3,
                    onItemSelected: (index) {
                      if (index == 0) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const MyVehiclesPage(),
                          ),
                        );
                      } else if (index == 1) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const AppointmentsPage(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF4B5563)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: const Color(0xFFF3F4F6)),
    );
  }
}

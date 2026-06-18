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

                          // ── Trees Impact (forest scene) ──
                          if (user != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 280,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: _ForestPainter(),
                                        ),
                                      ),
                                      Positioned(
                                        left: 24,
                                        right: 24,
                                        bottom: 20,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${user.treesPlanted}',
                                              style: const TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                height: 1,
                                                letterSpacing: -1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'cây xanh đã được trồng',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white.withValues(alpha: 0.9),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                GestureDetector(
                                                  onTap: () => _showTreePolicy(context),
                                                  child: Icon(
                                                    Icons.info_outline,
                                                    size: 14,
                                                    color: Colors.white.withValues(alpha: 0.45),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Cảm ơn bạn đã góp phần xây dựng một hành tinh xanh',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white.withValues(alpha: 0.55),
                                                fontStyle: FontStyle.italic,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 14),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(30),
                                                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.eco, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${user.loyaltyPoints} điểm quà tặng',
                                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFF3F4F6)),
    );
  }

  void _showTreePolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.forest, size: 24, color: Color(0xFF2E7D32)),
                SizedBox(width: 10),
                Text(
                  'Cam kết xanh',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Mỗi lần xe của bạn hoàn thành sửa chữa, chúng tôi thay mặt bạn trồng một cây xanh trên lãnh thổ Việt Nam, chung tay phủ xanh đất nước và bảo vệ môi trường.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Chương trình được hợp tác với các tổ chức phi lợi nhuận trong nước, đảm bảo mỗi cây được trồng đúng chủng loại bản địa, đúng khu vực và được chăm sóc đến khi trưởng thành.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.eco, size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 6),
                Text(
                  'Vì một Việt Nam xanh hơn, từng km xe chạy!',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ForestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky gradient
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    const skyColors = [Color(0xFF0A1628), Color(0xFF0F2A1A), Color(0xFF1B5E20)];
    canvas.drawRect(
      skyRect,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: skyColors,
      ).createShader(skyRect),
    );

    // Moon glow
    final moonCx = w * 0.78;
    final moonCy = h * 0.14;
    canvas.drawCircle(
      Offset(moonCx, moonCy),
      50,
      Paint()..shader = RadialGradient(
        colors: [const Color(0xFFFFF8E1).withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(moonCx, moonCy), radius: 50)),
    );

    // Crescent moon
    canvas.drawCircle(Offset(moonCx, moonCy), 22, Paint()..color = const Color(0xFFFFF8E1));
    canvas.drawCircle(Offset(moonCx + 7, moonCy - 5), 18, Paint()..color = const Color(0xFF0A1628));

    // Stars
    const starSeed = [
      (0.08, 0.06, 1.5, 0.6), (0.20, 0.14, 2.0, 0.4), (0.32, 0.04, 1.0, 0.7),
      (0.42, 0.20, 2.5, 0.3), (0.55, 0.10, 1.5, 0.5), (0.65, 0.22, 1.0, 0.6),
      (0.75, 0.06, 2.0, 0.35), (0.88, 0.18, 1.5, 0.5), (0.95, 0.10, 1.0, 0.7),
      (0.12, 0.28, 1.5, 0.4), (0.28, 0.32, 2.0, 0.3), (0.38, 0.24, 1.0, 0.55),
      (0.48, 0.34, 1.5, 0.35), (0.60, 0.30, 2.5, 0.25), (0.72, 0.28, 1.0, 0.6),
      (0.82, 0.36, 1.5, 0.4), (0.05, 0.38, 1.0, 0.5), (0.92, 0.30, 2.0, 0.3),
    ];
    for (final (x, y, r, o) in starSeed) {
      canvas.drawCircle(Offset(w * x, h * y), r, Paint()..color = Colors.white.withValues(alpha: o));
    }

    // Distant mountains
    final mt = Path()
      ..moveTo(0, h * 0.58)
      ..quadraticBezierTo(w * 0.12, h * 0.40, w * 0.22, h * 0.52)
      ..quadraticBezierTo(w * 0.28, h * 0.42, w * 0.35, h * 0.50)
      ..quadraticBezierTo(w * 0.42, h * 0.35, w * 0.52, h * 0.48)
      ..quadraticBezierTo(w * 0.58, h * 0.38, w * 0.65, h * 0.45)
      ..quadraticBezierTo(w * 0.72, h * 0.30, w * 0.82, h * 0.42)
      ..quadraticBezierTo(w * 0.88, h * 0.36, w * 0.95, h * 0.44)
      ..quadraticBezierTo(w * 0.98, h * 0.40, w, h * 0.46)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(mt, Paint()..color = const Color(0xFF0F3D1A).withValues(alpha: 0.45));

    // Mist layer
    final mistRect = Rect.fromLTWH(0, h * 0.48, w, h * 0.15);
    canvas.drawRect(
      mistRect,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.04),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(mistRect),
    );

    // Foreground trees
    const treeData = [
      (0.04, 0.68, 75.0, 32.0, 0.85), (0.10, 0.72, 65.0, 28.0, 0.80),
      (0.16, 0.66, 85.0, 36.0, 0.70), (0.23, 0.74, 60.0, 26.0, 0.85),
      (0.30, 0.70, 78.0, 34.0, 0.75), (0.38, 0.76, 55.0, 24.0, 0.85),
      (0.46, 0.64, 90.0, 38.0, 0.65), (0.54, 0.78, 50.0, 22.0, 0.80),
      (0.62, 0.70, 72.0, 30.0, 0.75), (0.70, 0.75, 62.0, 28.0, 0.85),
      (0.78, 0.66, 82.0, 35.0, 0.70), (0.86, 0.72, 68.0, 30.0, 0.80),
      (0.92, 0.68, 58.0, 26.0, 0.85), (0.97, 0.74, 70.0, 32.0, 0.75),
    ];
    for (final (x, by, ht, wd, op) in treeData) {
      _drawTree(canvas, w * x, h * by, ht, wd, const Color(0xFF0A2A0E).withValues(alpha: op));
    }

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, h - 8, w, 8),
      Paint()..color = const Color(0xFF0A2A0E).withValues(alpha: 0.9),
    );
    canvas.drawLine(
      Offset(0, h - 8), Offset(w, h - 8),
      Paint()..color = Colors.white.withValues(alpha: 0.10)..strokeWidth = 1.5,
    );

    // Fireflies
    const fireflies = [
      (0.20, 0.60, 2.0, 0.6), (0.35, 0.55, 2.5, 0.5),
      (0.50, 0.62, 1.5, 0.7), (0.65, 0.58, 3.0, 0.4),
      (0.80, 0.63, 2.0, 0.55), (0.15, 0.68, 1.5, 0.5),
      (0.45, 0.70, 2.5, 0.45), (0.75, 0.55, 1.5, 0.6),
    ];
    for (final (x, y, r, o) in fireflies) {
      canvas.drawCircle(
        Offset(w * x, h * y), r,
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: o),
      );
    }
  }

  void _drawTree(Canvas canvas, double x, double baseY, double height, double width, Color color) {
    // Trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, baseY), width: 3.5, height: height * 0.35),
        const Radius.circular(1.5),
      ),
      Paint()..color = color,
    );

    // Organic canopy
    final topY = baseY - height;
    final hw = width / 2;
    final canopy = Path()
      ..moveTo(x, topY)
      ..quadraticBezierTo(x + hw * 1.5, topY + height * 0.35, x + hw * 1.15, topY + height * 0.65)
      ..quadraticBezierTo(x + hw * 1.4, topY + height * 0.88, x, topY + height * 0.95)
      ..quadraticBezierTo(x - hw * 1.4, topY + height * 0.88, x - hw * 1.15, topY + height * 0.65)
      ..quadraticBezierTo(x - hw * 1.5, topY + height * 0.35, x, topY)
      ..close();
    canvas.drawPath(canopy, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

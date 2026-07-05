import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'personal_info_page.dart';
import '../../lookup/pages/tech_stats_page.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainerLow,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Cài đặt & Cá nhân',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final userName = authState is AuthAuthenticated ? authState.user.name : 'Trần Văn Bình';
            final userEmail = authState is AuthAuthenticated ? authState.user.email : 'tech@gmail.com';
            final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'T';

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
              child: Column(
                children: [
                  _buildProfileCard(context, userName, userEmail, userInitial),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildSettingsSection(context),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    String name,
    String email,
    String initial,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF006E2F), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF006E2F),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF191C1E),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF0F9D58),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF006E2F).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Kỹ thuật viên Xanh EV',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF006E2F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TechStatsPage()),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('Xem thống kê', 'Chi tiết →', Icons.bar_chart_rounded)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF006E2F), size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Thông tin cá nhân',
            subtitle: 'Họ tên, số điện thoại, xưởng',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PersonalInfoPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF006E2F).withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF006E2F), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Color(0xFF191C1E),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B7280), size: 20),
      onTap: onTap,
    );
  }


  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<AuthBloc>().add(const AuthLogoutRequested());
        },
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.onError,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

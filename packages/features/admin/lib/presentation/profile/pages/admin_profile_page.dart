import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:design_system/design_system.dart';
import 'package:auth/auth.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../bloc/notification_bloc.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_card.dart';
import '../widgets/profile_settings_section.dart';
import '../widgets/profile_logout_button.dart';
import '../../dashboard/pages/admin_revenue_report_page.dart';
import '../../dashboard/pages/inventory_page.dart';
import '../../vehicle_intake/pages/reception_hub_page.dart';
import '../../lookup/pages/customer_lookup_page.dart';
import '../../lookup/bloc/lookup_bloc.dart';
import '../../lookup/bloc/lookup_event.dart';
import 'change_password_page.dart';
import 'notification_list_page.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

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
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final user = state is ProfileLoaded ? state.user : null;

          return Scaffold(
            backgroundColor: AppColors.surface,
            body: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeader(
                    user: user,
                    onLogout: () {},
                  ),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quản lý hệ thống',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ProfileMenuCard(
                                icon: Icons.analytics_outlined,
                                title: 'Báo cáo doanh thu',
                                subtitle: 'Xem biểu đồ & số liệu',
                                color: AppColors.primary,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AdminRevenueReportPage(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              ProfileMenuCard(
                                icon: Icons.inventory_2_outlined,
                                title: 'Quản lý tồn kho',
                                subtitle: 'Kiểm tra & nhập phụ tùng',
                                color: const Color(0xFFD97706),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const InventoryPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ProfileMenuCard(
                                icon: Icons.people_outline_rounded,
                                title: 'Kỹ thuật viên',
                                subtitle: 'Danh sách nhân viên xưởng',
                                color: const Color(0xFF2563EB),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) => GetIt.instance<LookupBloc>()
                                          ..add(LoadLookupCategories()),
                                        child: const CustomerLookupPage(initialTab: 1),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              ProfileMenuCard(
                                icon: Icons.calendar_today_outlined,
                                title: 'Lịch hẹn hôm nay',
                                subtitle: 'Tổng hợp danh sách hẹn',
                                color: const Color(0xFF7C3AED),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ReceptionHubPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          'Cài đặt tài khoản',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ProfileSettingsSection(
                          items: [
                            SettingsItem(
                              icon: Icons.lock_outline_rounded,
                              label: 'Đổi mật khẩu',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ChangePasswordPage(),
                                  ),
                                );
                              },
                            ),
                            SettingsItem(
                              icon: Icons.notifications_none_rounded,
                              label: 'Thông báo hệ thống',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<NotificationBloc>(),
                                      child: const NotificationListPage(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SettingsItem(
                              icon: Icons.help_outline_rounded,
                              label: 'Hướng dẫn sử dụng',
                              onTap: () => _showFeatureUnderDevelopment(context),
                            ),
                            SettingsItem(
                              icon: Icons.shield_outlined,
                              label: 'Chính sách bảo mật',
                              onTap: () => _showFeatureUnderDevelopment(context),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        ProfileLogoutButton(
                          onTap: () => _showLogoutConfirmationDialog(context),
                        ),

                        const SizedBox(height: 24),
                        const Center(
                          child: Column(
                            children: [
                              Text(
                                'Xanh EV Admin App',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Phiên bản 1.2.0 • Build 2026.06.23',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng quản trị Xanh EV?',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProfileBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showFeatureUnderDevelopment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Tính năng đang được phát triển!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}


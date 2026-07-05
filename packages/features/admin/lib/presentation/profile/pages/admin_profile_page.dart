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
import 'data_export_page.dart';

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
                              icon: Icons.file_download_outlined,
                              label: 'Truy xuất dữ liệu',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const DataExportPage(),
                                  ),
                                );
                              },
                            ),
                            SettingsItem(
                              icon: Icons.menu_book_rounded,
                              label: 'Hướng dẫn sử dụng',
                              onTap: () => _showUsageGuide(context),
                            ),
                            SettingsItem(
                              icon: Icons.shield_outlined,
                              label: 'Chính sách bảo mật',
                              onTap: () => _showPrivacyPolicy(context),
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

  void _showUsageGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Hướng dẫn sử dụng', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _guideItem(Icons.analytics_outlined, 'Báo cáo doanh thu',
                  'Xem biểu đồ doanh thu theo tuần/tháng/năm. Lọc theo ngày, '
                  'xem top dịch vụ và hiệu suất kỹ thuật viên. Nhấn nút tải '
                  'xuất CSV hoặc PDF để lưu báo cáo.'),
              _guideItem(Icons.inventory_2_outlined, 'Quản lý tồn kho',
                  'Theo dõi số lượng phụ tùng, cảnh báo sắp hết hàng. '
                  'Nhập kho mới, cập nhật giá và số lượng tồn.'),
              _guideItem(Icons.people_outline_rounded, 'Kỹ thuật viên',
                  'Tra cứu danh sách nhân viên xưởng. Xem lịch sử công việc, '
                  'đơn hàng đã xử lý và xếp hạng hiệu suất.'),
              _guideItem(Icons.calendar_today_outlined, 'Lịch hẹn hôm nay',
                  'Danh sách khách hẹn trong ngày. Tiếp nhận, sắp xếp kỹ thuật '
                  'viên và theo dõi tiến trình sửa chữa.'),
              _guideItem(Icons.lock_outline_rounded, 'Đổi mật khẩu',
                  'Cập nhật mật khẩu tài khoản quản trị. Yêu cầu mật khẩu cũ '
                  'và xác nhận mật khẩu mới.'),
              _guideItem(Icons.notifications_none_rounded, 'Thông báo hệ thống',
                  'Xem danh sách thông báo từ hệ thống và khách hàng. '
                  'Đánh dấu đã đọc hoặc xoá thông báo.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Chính sách bảo mật', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Thông tin tài khoản và dữ liệu khách hàng được bảo vệ theo tiêu chuẩn '
          'bảo mật của Xanh EV. Chúng tôi cam kết không chia sẻ dữ liệu với bên '
          'thứ ba khi chưa có sự đồng ý.',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


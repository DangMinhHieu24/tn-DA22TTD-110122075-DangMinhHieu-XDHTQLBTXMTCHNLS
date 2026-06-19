import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:design_system/design_system.dart';
import '../../vehicles/widgets/customer_app_bar.dart';
import '../../vehicles/widgets/customer_bottom_nav.dart';
import '../../vehicles/pages/my_vehicles_page.dart';
import '../../account/pages/customer_account_page.dart';
import '../bloc/appointment_bloc.dart';
import '../widgets/appointment_card.dart';
import '../../../domain/entities/customer_appointment.dart';
import 'create_appointment_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late final AppointmentBloc _appointmentBloc;

  @override
  void initState() {
    super.initState();
    _appointmentBloc = GetIt.instance<AppointmentBloc>();
    _appointmentBloc.add(LoadAppointments());
  }

  @override
  void dispose() {
    _appointmentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _appointmentBloc,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              const CustomerAppBar(),
              Expanded(
                child: BlocConsumer<AppointmentBloc, AppointmentState>(
                  listener: (context, state) {
                    if (state is AppointmentCreated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Đặt lịch hẹn thành công!'),
                          backgroundColor: const Color(0xFF22C55E),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                    if (state is AppointmentCancelled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Đã hủy lịch hẹn'),
                          backgroundColor: AppColors.onSurfaceVariant,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                    if (state is AppointmentHistoryCleared) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Đã xoá lịch sử lịch hẹn'),
                          backgroundColor: const Color(0xFF22C55E),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                    if (state is AppointmentError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        _appointmentBloc.add(LoadAppointments());
                        // Wait a bit for the state to update
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Map
                            _buildMapSection(),
                            const SizedBox(height: 20),

                            // New appointment button
                            _buildNewAppointmentButton(context),
                            const SizedBox(height: 24),

                            // Appointments list
                            _buildAppointmentsList(state),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              CustomerBottomNav(
                selectedIndex: 1,
                onItemSelected: (index) => _handleNavigation(context, index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFE8EDF2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: const _MockMapPainter(),
            ),
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.store, size: 12, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dat Bike Hồ Chí Minh',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on, size: 18, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '123 Nguyễn Văn Linh, Quận 7, TP. Hồ Chí Minh',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '2.4 km',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewAppointmentButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCreatePage(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B5E20),
                    const Color(0xFF2E7D32),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white70,
                    size: 26,
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF1B5E20), size: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đặt lịch mới',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sắp xếp thời gian bảo dưỡng',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B5E20),
                    const Color(0xFF2E7D32),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(AppointmentState state) {
    if (state is AppointmentLoading || state is AppointmentInitial) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is AppointmentError) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Không thể tải lịch hẹn',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _appointmentBloc.add(LoadAppointments()),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final List<CustomerAppointment> appointments =
        state is AppointmentLoaded ? state.appointments : [];

    if (appointments.isEmpty) {
      return _buildEmptyState();
    }

    // Split into upcoming and past/cancelled
    final List<CustomerAppointment> upcoming = appointments
        .where((a) => a.isUpcoming)
        .toList();
    final List<CustomerAppointment> past = appointments
        .where((a) => !a.isUpcoming)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    final recentPast = past.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upcoming
        if (upcoming.isNotEmpty) ...[
          _buildSectionHeader(
            'Lịch trình',
            Icons.schedule_outlined,
            upcoming.length,
            onTap: () => _showAllAppointments('Lịch trình', upcoming, canCancel: true),
          ),
          const SizedBox(height: 12),
          ...upcoming.asMap().entries.map(
            (entry) => AppointmentCard(
              appointment: entry.value,
              isFirst: entry.key == 0,
              isLast: entry.key == upcoming.length - 1,
              onCancel: entry.value.canCancel
                  ? () => _appointmentBloc
                      .add(CancelExistingAppointment(entry.value.id))
                  : null,
            ),
          ),
        ],

        // Past / Cancelled (2 recent)
        if (recentPast.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSectionHeader(
            'Đã qua',
            Icons.history,
            past.length,
            onTap: () => _showAllAppointments('Đã qua', past),
          ),
          const SizedBox(height: 12),
          ...recentPast.asMap().entries.map(
            (entry) => Opacity(
              opacity: 0.65,
              child: AppointmentCard(
                appointment: entry.value,
                isFirst: entry.key == 0,
                isLast: entry.key == past.length - 1,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count, {VoidCallback? onTap}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'XEM TẤT CẢ',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  void _showAllAppointments(String title, List<CustomerAppointment> items, {bool canCancel = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (title == 'Đã qua' && items.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _showClearHistoryConfirm();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text(
                              'Xoá tất cả',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(Icons.close_rounded, size: 22, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 0),
                  itemBuilder: (_, i) => AppointmentCard(
                    appointment: items[i],
                    showTimeline: false,
                    onCancel: canCancel && items[i].canCancel
                        ? () {
                            Navigator.of(ctx).pop();
                            _appointmentBloc.add(CancelExistingAppointment(items[i].id));
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearHistoryConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá lịch sử'),
        content: const Text('Bạn có chắc muốn xoá tất cả lịch hẹn đã qua?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _appointmentBloc.add(ClearAppointmentHistory());
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có lịch hẹn nào',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn "Đặt lịch mới" để đặt lịch bảo dưỡng',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreatePage(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _appointmentBloc,
          child: const CreateAppointmentPage(),
        ),
      ),
    );
    if (result == true) {
      _appointmentBloc.add(LoadAppointments());
    }
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == 1) return; // Already on this page
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyVehiclesPage()),
      );
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerAccountPage()),
      );
    }
  }
}

class _MockMapPainter extends CustomPainter {
  const _MockMapPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD5DDE6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    paint.color = Colors.white.withValues(alpha: 0.85);
    paint.strokeWidth = 18;
    canvas.drawLine(
      Offset(0, size.height * 0.55),
      Offset(size.width * 0.65, size.height * 0.55),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.45, 0),
      Offset(size.width * 0.45, size.height * 0.7),
      paint,
    );

    paint.color = const Color(0xFFB0BCC8);
    paint.strokeWidth = 2;
    for (double x = 20; x < size.width * 0.65; x += 30) {
      _paintDash(canvas, paint, Offset(x, size.height * 0.55), Offset(x + 16, size.height * 0.55));
    }
    for (double y = 10; y < size.height * 0.7; y += 30) {
      _paintDash(canvas, paint, Offset(size.width * 0.45, y), Offset(size.width * 0.45, y + 16));
    }

    paint.color = Colors.white.withValues(alpha: 0.7);
    paint.strokeWidth = 12;
    final path = Path()
      ..moveTo(size.width * 0.65, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.4,
        size.width,
        size.height * 0.45,
      );
    canvas.drawPath(path, paint);

    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFC5D9C0).withValues(alpha: 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.08, size.width * 0.18, size.height * 0.20),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.72, size.height * 0.62, size.width * 0.20, size.height * 0.18),
        const Radius.circular(6),
      ),
      paint,
    );
  }

  void _paintDash(Canvas canvas, Paint paint, Offset start, Offset end) {
    final path = Path()..moveTo(start.dx, start.dy)..lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

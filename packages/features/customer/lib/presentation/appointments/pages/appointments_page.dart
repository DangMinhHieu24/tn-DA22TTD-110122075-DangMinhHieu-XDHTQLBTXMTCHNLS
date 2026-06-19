import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:design_system/design_system.dart';
import '../../../domain/entities/customer_appointment.dart';
import '../../vehicles/widgets/customer_app_bar.dart';
import '../../vehicles/widgets/customer_bottom_nav.dart';
import '../../vehicles/pages/my_vehicles_page.dart';
import '../../account/pages/customer_account_page.dart';
import '../../appointments/widgets/appointment_card.dart';
import '../bloc/appointment_bloc.dart';
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
                      _showSnackBar('Đặt lịch hẹn thành công!', const Color(0xFF22C55E));
                    }
                    if (state is AppointmentCancelled) {
                      _showSnackBar('Đã hủy lịch hẹn', AppColors.onSurfaceVariant);
                    }
                    if (state is AppointmentError) {
                      _showSnackBar(state.message, AppColors.error);
                    }
                  },
                  builder: (context, state) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        _appointmentBloc.add(LoadAppointments());
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Lịch hẹn',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const Spacer(),
                                _buildAddButton(context),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildContent(state),
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

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCreatePage(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 18, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Đặt lịch',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppointmentState state) {
    if (state is AppointmentLoading || state is AppointmentInitial) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state is AppointmentError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Không thể tải lịch hẹn'),
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

    final appointments =
        state is AppointmentLoaded ? state.appointments : const <CustomerAppointment>[];

    if (appointments.isEmpty) {
      return _buildEmptyState();
    }

    final upcoming = appointments.where((a) => a.isUpcoming).toList();
    final past = appointments.where((a) => !a.isUpcoming).toList();

    return Column(
      children: [
        if (upcoming.isNotEmpty) ...[
          _buildLabel('Sắp tới', Icons.upcoming, upcoming.length),
          const SizedBox(height: 10),
          ...upcoming.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompactTile(
                  appointment: a,
                  onTap: () => _showDetailSheet(a),
                  onCancel: a.canCancel
                      ? () => _appointmentBloc.add(CancelExistingAppointment(a.id))
                      : null,
                ),
              )),
          const SizedBox(height: 8),
        ],
        if (past.isNotEmpty) ...[
          _buildLabel('Gần đây', Icons.history, past.length),
          const SizedBox(height: 10),
          ...past.take(2).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompactTile(
                  appointment: a,
                  onTap: () => _showDetailSheet(a),
                ),
              )),
          if (past.length > 2) ...[
            const SizedBox(height: 2),
            Center(
              child: TextButton(
                onPressed: () => _showAllPastSheet(past),
                child: Text(
                  'Xem tất cả (${past.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLabel(String title, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3B82F6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.calendar_month,
                size: 48,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có lịch hẹn nào',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nhấn "Đặt lịch" để bắt đầu',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(CustomerAppointment a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDBDEE0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            AppointmentCard(
              appointment: a,
              onCancel: a.canCancel
                  ? () {
                      Navigator.pop(context);
                      _appointmentBloc.add(CancelExistingAppointment(a.id));
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showAllPastSheet(List<CustomerAppointment> past) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDBDEE0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'Lịch sử lịch hẹn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${past.length}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: past.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => Opacity(
                  opacity: 0.7,
                  child: AppointmentCard(appointment: past[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
    if (index == 1) return;
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

class _CompactTile extends StatelessWidget {
  final CustomerAppointment appointment;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _CompactTile({
    required this.appointment,
    required this.onTap,
    this.onCancel,
  });

  Color _statusColor() {
    switch (appointment.status) {
      case 'CONFIRMED':
        return const Color(0xFF22C55E);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final day = DateFormat('dd').format(appointment.scheduledAt);
    final month = 'Th${DateFormat('M').format(appointment.scheduledAt)}';
    final time = DateFormat('HH:mm').format(appointment.scheduledAt);
    final dow = DateFormat('EEEE', 'vi').format(appointment.scheduledAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    month,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$time • ${appointment.serviceTypeLabel}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusPill(color),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        dow,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      if (appointment.hasVehicle) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.directions_car, size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${appointment.vehicleBrand ?? ''} ${appointment.vehicleModel ?? ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Action
            if (onCancel != null)
              GestureDetector(
                onTap: () => _showCancelDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                ),
              )
            else
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        appointment.statusLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy lịch hẹn'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch hẹn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onCancel?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );
  }
}

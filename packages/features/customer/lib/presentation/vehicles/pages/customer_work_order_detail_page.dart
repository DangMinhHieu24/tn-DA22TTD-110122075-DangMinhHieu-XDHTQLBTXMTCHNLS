import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/customer_vehicle.dart';
import '../../../domain/entities/customer_work_order.dart';
import '../widgets/customer_bottom_nav.dart';
import 'my_vehicles_page.dart';
import '../../account/pages/customer_account_page.dart';

class CustomerWorkOrderDetailPage extends StatelessWidget {
  final CustomerWorkOrder workOrder;
  final CustomerVehicle vehicle;

  const CustomerWorkOrderDetailPage({
    super.key,
    required this.workOrder,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAIReminderBanner(),
                    const SizedBox(height: 24),
                    _buildServiceProgress(),
                    const SizedBox(height: 24),
                    _buildTechnicalAlert(),
                    const SizedBox(height: 24),
                    _buildMaintenanceHistory(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            CustomerBottomNav(
              selectedIndex: 0,
              onItemSelected: (index) {
                if (index == 0) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const MyVehiclesPage(),
                    ),
                    (route) => false,
                  );
                } else if (index == 3) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const CustomerAccountPage(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top App Bar ───────────────────────────────────────────────────────────
  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          // Title
          Text(
            'Chi tiết phiếu',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          // Notification button
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── AI Reminder Banner ────────────────────────────────────────────────────
  Widget _buildAIReminderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI gợi ý: Xe của bạn sắp đến\nhạn bảo dưỡng.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 0.95,
                    minHeight: 6,
                    backgroundColor:
                        AppColors.primaryContainer.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hiện tại: 9.500 km',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Còn 500 km',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Bảo dưỡng tại: 10.000 km',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đặt lịch ngay',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward,
                          size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Service Progress Stepper ──────────────────────────────────────────────
  Widget _buildServiceProgress() {
    final steps = [
      _StepInfo('Tiếp nhận', Icons.check, true, false),
      _StepInfo('Kiểm tra', Icons.check, true, false),
      _StepInfo('Đang sửa', Icons.build, false, true),
      _StepInfo('Thanh toán', Icons.payments, false, false),
      _StepInfo('Hoàn thành', Icons.flag, false, false),
    ];

    final activeIndex = _getActiveStepIndex(workOrder.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiến độ dịch vụ',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Stepper row
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background line
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 16,
                    child: Container(
                      height: 2,
                      color: AppColors.surfaceContainerHigh,
                    ),
                  ),
                  // Active progress line
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 16,
                    child: FractionallySizedBox(
                      widthFactor: activeIndex / (steps.length - 1),
                      alignment: Alignment.centerLeft,
                      child: Container(height: 2, color: AppColors.primary),
                    ),
                  ),
                  // Steps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: steps.asMap().entries.map((entry) {
                      final i = entry.key;
                      final step = entry.value;
                      final isDone = i < activeIndex;
                      final isActive = i == activeIndex;
                      return _buildStepItem(step, isDone, isActive);
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Vehicle mini card
              _buildVehicleMiniCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(_StepInfo step, bool isDone, bool isActive) {
    Color bgColor;
    Color iconColor;
    if (isDone) {
      bgColor = AppColors.primary;
      iconColor = Colors.white;
    } else if (isActive) {
      bgColor = AppColors.primaryContainer;
      iconColor = AppColors.onPrimaryContainer;
    } else {
      bgColor = AppColors.surfaceContainerHigh;
      iconColor = AppColors.outline;
    }

    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Container(
            width: isActive ? 40 : 32,
            height: isActive ? 40 : 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(999),
              border: isActive
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Icon(step.icon, size: isActive ? 20 : 16, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            step.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isActive
                  ? AppColors.primary
                  : isDone
                      ? AppColors.onSurfaceVariant
                      : AppColors.outline,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleMiniCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.electric_bike,
                color: AppColors.onSurfaceVariant, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.model,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Biển số: ${vehicle.licensePlate}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.security,
                          size: 11, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        'Còn bảo hành: ${vehicle.warrantyDaysRemaining ?? 0} ngày',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (workOrder.scheduledTime != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'HẸN TRẢ:',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFFD97706),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  workOrder.scheduledTime!,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: const Color(0xFFD97706),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Technical Alert ───────────────────────────────────────────────────────
  Widget _buildTechnicalAlert() {
    if ((workOrder.notes ?? '').isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Thông báo kỹ thuật',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: const Border(
              left: BorderSide(color: AppColors.secondary, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.secondary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workOrder.notes ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurface,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chi phí phát sinh: 450.000đ',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '(Tiết kiệm 70.000đ so với giá niêm yết)',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Phê duyệt',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            foregroundColor: AppColors.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Từ chối',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
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
      ],
    );
  }

  // ─── Maintenance History Timeline ──────────────────────────────────────────
  Widget _buildMaintenanceHistory() {
    final services = workOrder.services;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử bảo trì',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (services.isEmpty)
          Text(
            'Chưa có hạng mục dịch vụ',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.onSurfaceVariant),
          )
        else
          ...services.asMap().entries.map((entry) {
            final i = entry.key;
            final service = entry.value;
            final isLast = i == services.length - 1;
            final isFirst = i == 0;
            return _buildTimelineItem(
              title: service.serviceType,
              description: service.description ?? '',
              date: _formatDate(workOrder.createdAt),
              isFirst: isFirst,
              isLast: isLast,
            );
          }),
        const SizedBox(height: 12),
        // "Xem thêm" button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.expand_more, size: 18),
            label: Text(
              'Xem thêm',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side:
                  BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String description,
    required String date,
    required bool isFirst,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isFirst
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isFirst
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          date,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  int _getActiveStepIndex(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'CHO_XU_LY':
        return 0;
      case 'IN_PROGRESS':
      case 'DANG_XU_LY':
        return 2;
      case 'WAITING_PARTS':
        return 1;
      case 'COMPLETED':
      case 'PAID':
        return 4;
      default:
        return 0;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _StepInfo {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isActive;
  const _StepInfo(this.label, this.icon, this.isDone, this.isActive);
}

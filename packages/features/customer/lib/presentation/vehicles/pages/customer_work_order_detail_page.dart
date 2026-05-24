import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/customer_maintenance_log.dart';
import '../../../domain/entities/customer_vehicle.dart';
import '../../../domain/entities/customer_work_order.dart';
import '../../../domain/repositories/customer_repository.dart';
import '../widgets/customer_bottom_nav.dart';
import 'my_vehicles_page.dart';
import '../../account/pages/customer_account_page.dart';

class CustomerWorkOrderDetailPage extends StatefulWidget {
  final CustomerWorkOrder workOrder;
  final CustomerVehicle vehicle;

  const CustomerWorkOrderDetailPage({
    super.key,
    required this.workOrder,
    required this.vehicle,
  });

  @override
  State<CustomerWorkOrderDetailPage> createState() => _CustomerWorkOrderDetailPageState();
}

class _CustomerWorkOrderDetailPageState extends State<CustomerWorkOrderDetailPage> {
  late CustomerWorkOrder _currentWorkOrder;
  late final CustomerRepository _customerRepository;
  late final WorkOrderRealtimeService _realtimeService;
  List<CustomerMaintenanceLog> _maintenanceLogs = const [];
  bool _isLoadingMaintenanceLogs = false;

  @override
  void initState() {
    super.initState();
    _currentWorkOrder = widget.workOrder;
    _customerRepository = GetIt.instance<CustomerRepository>();
    _realtimeService = WorkOrderRealtimeService();
    _startRealtime();
  }

  @override
  void dispose() {
    _realtimeService.unsubscribe();
    super.dispose();
  }

  void _startRealtime() {
    _realtimeService.subscribeToWorkOrder(
      workOrderId: widget.workOrder.id,
      onChanged: _refreshWorkOrder,
    );
    _refreshWorkOrder();
    _refreshMaintenanceLogs();
  }

  Future<void> _refreshWorkOrder() async {
    final result = await _customerRepository.getWorkOrdersByVehicle(widget.vehicle.id);
    result.fold(
      (_) {},
      (workOrders) {
        if (!mounted) return;
        final updated = workOrders.firstWhere(
          (order) => order.id == _currentWorkOrder.id,
          orElse: () => _currentWorkOrder,
        );

        if (updated != _currentWorkOrder) {
          setState(() {
            _currentWorkOrder = updated;
          });
        }
      },
    );
    _refreshMaintenanceLogs();
  }

  Future<void> _refreshMaintenanceLogs() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMaintenanceLogs = true;
    });

    final result = await _customerRepository.getMaintenanceLogsByVehicle(widget.vehicle.id);
    result.fold(
      (_) {},
      (logs) {
        if (!mounted) return;
        setState(() {
          _maintenanceLogs = logs;
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _isLoadingMaintenanceLogs = false;
    });
  }

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

  // ─── Header Section ───────────────────────────────────────────────────────
  Widget _buildHeaderSection() {
    final vehicle = widget.vehicle;

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
          if (_currentWorkOrder.scheduledTime != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'DỰ KIẾN XONG:',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFFD97706),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _formatScheduledTime(_currentWorkOrder.scheduledTime!),
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

  // ─── Service Progress Stepper ──────────────────────────────────────────────
  Widget _buildServiceProgress() {
    final activeIndex = _getActiveStepIndex(_currentWorkOrder.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkStatusTimelineCard(
          title: 'Tiến độ dịch vụ',
          activeStep: activeIndex,
        ),
      ],
    );
  }

  // ─── Technical Alert ───────────────────────────────────────────────────────
  Widget _buildTechnicalAlert() {
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
                      'Khách báo xe sụt pin nhanh khi tăng tốc mạnh. Cần kiểm tra pack pin và cập nhật cấu hình BMS.',
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
    final logs = _maintenanceLogs;
    final visibleLogs = logs.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Lịch sử bảo trì',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (logs.isNotEmpty)
              Text(
                '${logs.length} mục',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingMaintenanceLogs)
          Text(
            'Đang tải lịch sử bảo trì...',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.onSurfaceVariant),
          )
        else if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Xe này chưa có lịch sử bảo trì',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          )
        else
          ...visibleLogs.asMap().entries.map((entry) {
            final i = entry.key;
            final log = entry.value;
            final isLast = i == visibleLogs.length - 1;
            final isFirst = i == 0;
            return _buildTimelineItem(
              title: log.serviceSummary?.trim().isNotEmpty == true
                  ? log.serviceSummary!.trim()
                  : _mapServiceTypeLabel(log.serviceType ?? ''),
              description: _buildMaintenanceDescription(log),
              date: _formatDate(log.performedAt),
              isFirst: isFirst,
              isLast: isLast,
            );
          }),
        const SizedBox(height: 12),
        if (logs.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: open full maintenance history screen.
              },
              icon: const Icon(Icons.history, size: 18),
              label: Text(
                'Xem tất cả lịch sử',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          date,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
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
      case 'INSPECTION':
        return 1;
      case 'IN_PROGRESS':
      case 'DANG_XU_LY':
        return 2;
      case 'COMPLETED':
      case 'PAID':
        return 3;
      default:
        return 0;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatScheduledTime(String scheduledTime) {
    final parsed = DateTime.tryParse(scheduledTime);
    if (parsed == null) {
      return scheduledTime;
    }

    return DateFormat('HH:mm, dd/MM/yyyy', 'vi').format(parsed.toLocal());
  }

  String _mapServiceTypeLabel(String serviceType) {
    switch (serviceType.toUpperCase()) {
      case 'MAINTENANCE':
        return 'Bảo dưỡng định kỳ';
      case 'BATTERY_CHECK':
        return 'Kiểm tra pin & BMS';
      case 'BRAKES_TIRES':
        return 'Phanh & lốp';
      case 'OTHER_REPAIR':
        return 'Sửa chữa khác';
      default:
        return serviceType;
    }
  }

  String _buildMaintenanceDescription(CustomerMaintenanceLog log) {
    final parts = <String>[];

    if ((log.notes ?? '').trim().isNotEmpty) {
      parts.add(log.notes!.trim());
    }

    if (log.odometerKm != null) {
      parts.add('Km: ${log.odometerKm}');
    }

    if (log.nextServiceKm != null) {
      parts.add('Lần sau: ${log.nextServiceKm} km');
    }

    return parts.join(' • ');
  }
}

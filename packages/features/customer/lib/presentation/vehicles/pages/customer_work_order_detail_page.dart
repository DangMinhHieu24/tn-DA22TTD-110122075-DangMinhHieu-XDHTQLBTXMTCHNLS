import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/customer_maintenance_log.dart';
import '../../../domain/entities/customer_vehicle.dart';
import '../../../domain/entities/customer_work_order.dart';
import '../../../domain/repositories/customer_repository.dart';
import '../widgets/customer_bottom_nav.dart';
import 'my_vehicles_page.dart';
import '../../account/pages/customer_account_page.dart';
import '../../chat/widgets/chat_floating_bubble.dart';
import '../../notifications/pages/customer_notification_list_page.dart';

String _serviceLabel(String type) => switch (type) {
      'MAINTENANCE' => 'Bảo dưỡng định kỳ',
      'BATTERY_CHECK' => 'Kiểm tra pin/sạc',
      'BRAKES_TIRES' => 'Phanh & Lốp',
      'OTHER_REPAIR' => 'Sửa chữa khác',
      _ => type,
    };

String _statusLabel(String status) => switch (status.toUpperCase()) {
      'PENDING' || 'CHO_XU_LY' => 'Chờ xử lý',
      'INSPECTION' => 'Đang kiểm tra',
      'IN_PROGRESS' || 'DANG_XU_LY' => 'Đang sửa chữa',
      'COMPLETED' => 'Đã hoàn thành',
      'PAID' => 'Đã thanh toán',
      _ => status,
    };

Color _statusColor(String status) => switch (status.toUpperCase()) {
      'PENDING' || 'CHO_XU_LY' => const Color(0xFFF59E0B),
      'INSPECTION' => const Color(0xFF3B82F6),
      'IN_PROGRESS' || 'DANG_XU_LY' => const Color(0xFF8B5CF6),
      'COMPLETED' => const Color(0xFF10B981),
      'PAID' => const Color(0xFF059669),
      _ => AppColors.onSurfaceVariant,
    };

String _paymentMethodLabel(String? method) => switch (method?.toUpperCase()) {
      'CASH' => 'Tiền mặt',
      'CARD' => 'Thẻ ngân hàng',
      'TRANSFER' => 'Chuyển khoản',
      _ => method ?? 'Chưa thanh toán',
    };

class CustomerWorkOrderDetailPage extends StatefulWidget {
  final CustomerWorkOrder workOrder;
  final CustomerVehicle vehicle;

  const CustomerWorkOrderDetailPage({
    super.key,
    required this.workOrder,
    required this.vehicle,
  });

  @override
  State<CustomerWorkOrderDetailPage> createState() =>
      _CustomerWorkOrderDetailPageState();
}

class _CustomerWorkOrderDetailPageState
    extends State<CustomerWorkOrderDetailPage> {
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
    final result =
        await _customerRepository.getWorkOrdersByVehicle(widget.vehicle.id);
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

    final result =
        await _customerRepository.getMaintenanceLogsByVehicle(widget.vehicle.id);
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

  // ─── Format helpers ────────────────────────────────────────────────────────
  String _formatPrice(double amount) {
    if (amount <= 0) return '0₫';
    final whole = amount.floor();
    final parts = <String>[];
    var s = whole.toString();
    while (s.length > 3) {
      parts.add(s.substring(s.length - 3));
      s = s.substring(0, s.length - 3);
    }
    parts.add(s);
    return '${parts.reversed.join('.')}₫';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatDateTime(DateTime date) {
    return DateFormat('HH:mm, dd/MM/yyyy', 'vi').format(date.toLocal());
  }

  String _formatScheduledTime(String scheduledTime) {
    final parsed = DateTime.tryParse(scheduledTime);
    if (parsed == null) return scheduledTime;
    return DateFormat('HH:mm, dd/MM/yyyy', 'vi').format(parsed.toLocal());
  }

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

  double get _computedTotal {
    if (_currentWorkOrder.totalCost != null &&
        _currentWorkOrder.totalCost! > 0) {
      return _currentWorkOrder.totalCost!;
    }
    final serviceCost = _currentWorkOrder.services
        .fold<double>(0, (sum, s) => sum + (s.price ?? 0));
    final partsCost = _currentWorkOrder.partsUsed
        .fold<double>(0, (sum, p) => sum + p.totalPrice);
    return serviceCost + partsCost;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Order Info Card ──────────────────────────────────
                    _buildOrderInfoCard(),
                    const SizedBox(height: 16),

                    // ── Vehicle Card ─────────────────────────────────────
                    _buildVehicleCard(),
                    const SizedBox(height: 24),

                    // ── Service Progress ─────────────────────────────────
                    _buildServiceProgress(),
                    const SizedBox(height: 24),

                    // ── Technical Alert (pending services) ───────────────
                    _buildTechnicalAlert(),

                    // ── Technician Info ──────────────────────────────────
                    if (_currentWorkOrder.technicianName != null) ...[
                      _buildTechnicianCard(),
                      const SizedBox(height: 24),
                    ],

                    // ── Services List ────────────────────────────────────
                    if (_currentWorkOrder.services.isNotEmpty) ...[
                      _buildServicesSection(),
                      const SizedBox(height: 24),
                    ],

                    // ── Parts Used ───────────────────────────────────────
                    if (_currentWorkOrder.partsUsed.isNotEmpty) ...[
                      _buildPartsUsedSection(),
                      const SizedBox(height: 24),
                    ],

                    // ── Cost Summary ─────────────────────────────────────
                    _buildCostSummaryCard(),
                    const SizedBox(height: 24),

                    // ── Photos ───────────────────────────────────────────
                    if (_currentWorkOrder.photos.isNotEmpty) ...[
                      _buildPhotosSection(),
                      const SizedBox(height: 24),
                    ],

                    // ── Maintenance History ──────────────────────────────
                    _buildMaintenanceHistory(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top App Bar ──────────────────────────────────────────────────────────
  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.arrow_back,
                  color: AppColors.primary, size: 24),
            ),
          ),
          Text(
            'Chi tiết phiếu',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomerNotificationListPage(),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColors.primary, size: 24),
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
          ),
        ],
      ),
    );
  }

  // ─── Order Info Card ──────────────────────────────────────────────────────
  Widget _buildOrderInfoCard() {
    final wo = _currentWorkOrder;
    final statusColor = _statusColor(wo.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number + status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã phiếu',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      wo.orderNumber,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _statusLabel(wo.status),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Meta info grid
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Ngày tạo',
            value: _formatDateTime(wo.createdAt),
          ),
          if (wo.completedAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.check_circle_outline,
              label: 'Hoàn thành',
              value: _formatDateTime(wo.completedAt!),
              valueColor: const Color(0xFF10B981),
            ),
          ],
          if (wo.scheduledTime != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.schedule_outlined,
              label: 'Dự kiến xong',
              value: _formatScheduledTime(wo.scheduledTime!),
              valueColor: const Color(0xFFF59E0B),
            ),
          ],
          if (wo.estimatedHours != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.timer_outlined,
              label: 'Ước tính',
              value: '${wo.estimatedHours!.toStringAsFixed(wo.estimatedHours! % 1 == 0 ? 0 : 1)} giờ',
            ),
          ],
          if (wo.notes != null && wo.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.notes_outlined,
              label: 'Ghi chú',
              value: wo.notes!.trim(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              children: [
                TextSpan(text: '$label: '),
                TextSpan(
                  text: value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: valueColor ?? AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Vehicle Card ─────────────────────────────────────────────────────────
  Widget _buildVehicleCard() {
    final vehicle = widget.vehicle;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.electric_bike,
                color: AppColors.primary, size: 28),
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
                if (vehicle.currentKm != null)
                  Text(
                    'Số km: ${vehicle.currentKm} km',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (vehicle.warrantyDaysRemaining != null &&
              vehicle.warrantyDaysRemaining! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.security, size: 14, color: AppColors.primary),
                  Text(
                    '${vehicle.warrantyDaysRemaining} ngày',
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
    );
  }

  // ─── Service Progress ─────────────────────────────────────────────────────
  Widget _buildServiceProgress() {
    final activeIndex = _getActiveStepIndex(_currentWorkOrder.status);

    return WorkStatusTimelineCard(
      title: 'Tiến độ dịch vụ',
      activeStep: activeIndex,
    );
  }

  // ─── Technical Alert ──────────────────────────────────────────────────────
  Widget _buildTechnicalAlert() {
    final pendingServices =
        _currentWorkOrder.services.where((s) => s.isPending).toList();

    if (pendingServices.isEmpty) return const SizedBox.shrink();

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
        ...pendingServices.map((service) {
          final svcLabel = _serviceLabel(service.serviceType);
          final priceText = service.price != null
              ? _formatPrice(service.price!)
              : 'Liên hệ báo giá';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          svcLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.description ?? 'Không có mô tả',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onSurface,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chi phí phát sinh: $priceText',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approveService(service),
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
                            onPressed: () => _rejectService(service),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide.none,
                              backgroundColor:
                                  AppColors.surfaceContainerHigh,
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
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _approveService(CustomerWorkOrderService service) async {
    final result = await _customerRepository.approveService(
      _currentWorkOrder.id,
      service.id,
    );
    if (!mounted) return;
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phê duyệt thất bại')),
      ),
      (_) => _refreshWorkOrder(),
    );
  }

  Future<void> _rejectService(CustomerWorkOrderService service) async {
    final result = await _customerRepository.rejectService(
      _currentWorkOrder.id,
      service.id,
    );
    if (!mounted) return;
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Từ chối thất bại')),
      ),
      (_) => _refreshWorkOrder(),
    );
  }

  // ─── Technician Card ──────────────────────────────────────────────────────
  Widget _buildTechnicianCard() {
    final wo = _currentWorkOrder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.person_outline,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kỹ thuật viên phụ trách',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  wo.technicianName!,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (wo.technicianPhone != null)
                  Text(
                    wo.technicianPhone!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (wo.technicianName != null)
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  showChatPanel(context, initialTab: 1);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── Services Section ─────────────────────────────────────────────────────
  Widget _buildServicesSection() {
    final services = _currentWorkOrder.services;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dịch vụ thực hiện',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: services.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final isLast = i == services.length - 1;

              Color statusClr;
              IconData statusIco;
              String statusTxt;
              if (s.isApproved && s.isDone) {
                statusClr = const Color(0xFF10B981);
                statusIco = Icons.check_circle_rounded;
                statusTxt = 'Hoàn thành';
              } else if (s.isRejected) {
                statusClr = AppColors.error;
                statusIco = Icons.cancel_rounded;
                statusTxt = 'Từ chối';
              } else if (s.isPending) {
                statusClr = const Color(0xFFF59E0B);
                statusIco = Icons.pending_rounded;
                statusTxt = 'Chờ duyệt';
              } else {
                statusClr = const Color(0xFF3B82F6);
                statusIco = Icons.build_outlined;
                statusTxt = 'Đang thực hiện';
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(statusIco, color: statusClr, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.serviceName ??
                                    _serviceLabel(s.serviceType),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (s.description != null &&
                                  s.description!.trim().isNotEmpty)
                                Text(
                                  s.description!.trim(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (s.price != null)
                              Text(
                                _formatPrice(s.price!),
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusClr.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusTxt,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: statusClr,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      indent: 44,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Parts Used Section ───────────────────────────────────────────────────
  Widget _buildPartsUsedSection() {
    final parts = _currentWorkOrder.partsUsed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linh kiện thay thế',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: parts.asMap().entries.map((entry) {
              final i = entry.key;
              final part = entry.value;
              final isLast = i == parts.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.settings_outlined,
                              size: 18, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                part.partName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${part.quantity} x ${_formatPrice(part.unitPrice)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatPrice(part.totalPrice),
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      indent: 60,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Cost Summary Card ────────────────────────────────────────────────────
  Widget _buildCostSummaryCard() {
    final wo = _currentWorkOrder;
    final total = _computedTotal;
    final isPaid = wo.status.toUpperCase() == 'PAID';

    final serviceCost =
        wo.services.fold<double>(0, (sum, s) => sum + (s.price ?? 0));
    final partsCost =
        wo.partsUsed.fold<double>(0, (sum, p) => sum + p.totalPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaid
            ? const Color(0xFF059669).withValues(alpha: 0.06)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid
              ? const Color(0xFF059669).withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Thanh toán',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 14, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text(
                        'Đã thanh toán',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFF059669),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Service cost line
          if (serviceCost > 0) ...[
            _buildCostLine('Phí dịch vụ', serviceCost),
            const SizedBox(height: 6),
          ],

          // Parts cost line
          if (partsCost > 0) ...[
            _buildCostLine('Linh kiện', partsCost),
            const SizedBox(height: 6),
          ],

          if ((serviceCost > 0 || partsCost > 0) && total > 0) ...[
            Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
          ],

          // Total
          Row(
            children: [
              Text(
                'Tổng cộng',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                total > 0 ? _formatPrice(total) : 'Chưa xác định',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          // Payment method
          if (wo.paymentMethod != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.payment_outlined,
                    size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Phương thức: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  _paymentMethodLabel(wo.paymentMethod),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // Paid at
          if (wo.paidAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Thanh toán lúc: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDateTime(wo.paidAt!),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostLine(String label, double amount) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          _formatPrice(amount),
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Photos Section ───────────────────────────────────────────────────────
  Widget _buildPhotosSection() {
    final intakePhotos =
        _currentWorkOrder.photos.where((p) => p.isIntake).toList();
    final afterPhotos =
        _currentWorkOrder.photos.where((p) => p.isAfterRepair).toList();

    if (intakePhotos.isEmpty && afterPhotos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              'Ảnh xe',
              style: AppTextStyles.titleSmall
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (intakePhotos.isNotEmpty)
              Expanded(
                child: _buildPhotoColumn(
                  label: 'Trước',
                  labelColor: const Color(0xFFF59E0B),
                  icon: Icons.camera_front_outlined,
                  photos: intakePhotos,
                ),
              ),
            if (intakePhotos.isNotEmpty && afterPhotos.isNotEmpty)
              const SizedBox(width: 10),
            if (afterPhotos.isNotEmpty)
              Expanded(
                child: _buildPhotoColumn(
                  label: 'Sau',
                  labelColor: const Color(0xFF10B981),
                  icon: Icons.camera_rear_outlined,
                  photos: afterPhotos,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoColumn({
    required String label,
    required Color labelColor,
    required IconData icon,
    required List<CustomerWorkOrderPhoto> photos,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: labelColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: labelColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: labelColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${photos.length}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: labelColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: photos.map((photo) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildPhotoItem(photo, photos.indexOf(photo), photos),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(CustomerWorkOrderPhoto photo, int index,
      List<CustomerWorkOrderPhoto> allPhotos) {
    return GestureDetector(
      onTap: () => _openPhotoViewer(allPhotos, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            photo.photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surfaceContainerHighest,
              child: const Icon(Icons.image_not_supported_outlined,
                  color: AppColors.onSurfaceVariant),
            ),
            loadingBuilder: (_, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AppColors.surfaceContainerHighest,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openPhotoViewer(
      List<CustomerWorkOrderPhoto> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: photos.length,
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(
                  child: Image.network(
                    photos[i].photoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Maintenance History ──────────────────────────────────────────────────
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
                style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.w700),
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

  // ─── Helpers ──────────────────────────────────────────────────────────────
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
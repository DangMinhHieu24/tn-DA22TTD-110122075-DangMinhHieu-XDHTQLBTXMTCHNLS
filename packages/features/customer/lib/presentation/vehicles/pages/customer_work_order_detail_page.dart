import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/customer_vehicle.dart';
import '../../../domain/entities/customer_work_order.dart';
import '../../../domain/repositories/customer_repository.dart';

String _serviceLabel(String type) => switch (type) {
  'MAINTENANCE' => 'Bảo dưỡng định kỳ',
  'BATTERY_CHECK' => 'Kiểm tra pin/sạc',
  'BRAKES_TIRES' => 'Phanh & Lốp',
  'OTHER_REPAIR' => 'Sửa chữa khác',
  _ => type,
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
  State<CustomerWorkOrderDetailPage> createState() => _CustomerWorkOrderDetailPageState();
}

class _CustomerWorkOrderDetailPageState extends State<CustomerWorkOrderDetailPage> {
  late CustomerWorkOrder _currentWorkOrder;
  late final CustomerRepository _customerRepository;
  late final WorkOrderRealtimeService _realtimeService;


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
                    _buildServicesList(),
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
    final pendingServices = _currentWorkOrder.services
        .where((s) => s.isPending)
        .toList();

    if (pendingServices.isEmpty) return const SizedBox.shrink();

    String formatPrice(double amount) {
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
              ? formatPrice(service.price!)
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
                      Row(
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
                        ],
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
          );
        }),
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

  // ─── Maintenance History Timeline ──────────────────────────────────────────
  Widget _buildServicesList() {
    final services = _currentWorkOrder.services;
    if (services.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách hạng mục',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...services.map((s) => _buildServiceCard(s)),
      ],
    );
  }

  Widget _buildServiceCard(CustomerWorkOrderService s) {
    final svcLabel = _serviceLabel(s.serviceType);
    final priceText = s.price != null ? _formatPrice(s.price!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                s.isDone ? Icons.check_circle : Icons.build_outlined,
                size: 16,
                color: s.isDone ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  svcLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: s.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if ((s.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.description!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (priceText != null)
            Text(
              priceText,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

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

}

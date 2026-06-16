import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/models/work_order_model.dart';
import '../../../data/repositories/vehicle_intake_repository.dart';

class AdminVehicleDetailSheet extends StatefulWidget {
  final VehicleModel vehicle;
  final ValueChanged<String> onIntakePressed;

  const AdminVehicleDetailSheet({
    super.key,
    required this.vehicle,
    required this.onIntakePressed,
  });

  static void show(
    BuildContext context,
    VehicleModel vehicle,
    ValueChanged<String> onIntakePressed,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminVehicleDetailSheet(
        vehicle: vehicle,
        onIntakePressed: onIntakePressed,
      ),
    );
  }

  @override
  State<AdminVehicleDetailSheet> createState() => _AdminVehicleDetailSheetState();
}

class _AdminVehicleDetailSheetState extends State<AdminVehicleDetailSheet> {
  List<WorkOrderModel> _history = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final repo = GetIt.instance<VehicleIntakeRepository>();
      final history = await repo.getVehicleHistory(widget.vehicle.id);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFF9800);
      case 'IN_PROGRESS':
        return const Color(0xFF2196F3);
      case 'INSPECTION':
        return const Color(0xFF9C27B0);
      case 'COMPLETED':
        return const Color(0xFF4CAF50);
      case 'PAID':
        return const Color(0xFF006E2F);
      case 'CANCELLED':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'PENDING':
        return 'CHỜ XỬ LÝ';
      case 'IN_PROGRESS':
        return 'ĐANG THỰC HIỆN';
      case 'INSPECTION':
        return 'KIỂM TRA';
      case 'COMPLETED':
        return 'HOÀN THÀNH';
      case 'PAID':
        return 'ĐÃ THANH TOÁN';
      case 'CANCELLED':
        return 'ĐÃ HỦY';
      default:
        return 'KHÔNG RÕ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBDEE0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header: Plate & Brand
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDBDEE0)),
                  ),
                  child: Text(
                    v.licensePlate,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF191C1E),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.model,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF006E2F),
                        ),
                      ),
                      Text(
                        '${v.brand ?? 'Không rõ hãng'} • ${v.color ?? 'Không rõ màu'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3D4A3D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Customer Info
            const Text(
              'THÔNG TIN KHÁCH HÀNG',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6D7B6C),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFECEEF0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF006E2F)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.ownerName ?? 'Chưa cập nhật tên',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v.ownerPhone ?? 'Chưa cập nhật SĐT',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3D4A3D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Status
            const Text(
              'TRẠNG THÁI XE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6D7B6C),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    icon: Icons.speed,
                    label: 'Số KM',
                    value: v.currentKm != null ? '${v.currentKm} km' : '--',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusItem(
                    icon: Icons.verified_user_outlined,
                    label: 'Bảo hành',
                    value: v.isUnderWarranty ? 'Còn hạn' : 'Hết hạn',
                    valueColor: v.isUnderWarranty ? const Color(0xFF006E2F) : const Color(0xFFBA1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Vehicle History ──────────────────────────────────────────
            if (_isLoadingHistory) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF006E2F),
                    ),
                  ),
                ),
              ),
            ] else if (_history.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LỊCH SỬ SỬA CHỮA (${_history.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6D7B6C),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._history.take(3).map((wo) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFECEEF0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            wo.orderNumber,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF006E2F),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(wo.status),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusText(wo.status),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (wo.notes != null && wo.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        wo.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3D4A3D),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              )),
              if (_history.length > 3)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VehicleHistoryPage(
                          licensePlate: v.licensePlate,
                          vehicleModel: v.model,
                          vehicleColor: v.color,
                          historyItems: _history
                              .map((wo) => wo.toWorkHistoryItem(licensePlate: v.licensePlate))
                              .toList(),
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF006E2F),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],

            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onIntakePressed(v.licensePlate);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006E2F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tạo Phiếu Tiếp Nhận',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECEEF0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6D7B6C)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6D7B6C),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF191C1E),
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

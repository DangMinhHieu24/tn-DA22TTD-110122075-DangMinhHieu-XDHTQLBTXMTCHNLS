import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/customer_work_order.dart';

class CustomerWorkOrderCard extends StatelessWidget {
  final CustomerWorkOrder workOrder;
  final VoidCallback? onTap;

  const CustomerWorkOrderCard({
    super.key,
    required this.workOrder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _statusColor(workOrder.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _statusIcon(workOrder.status),
                color: _statusColor(workOrder.status),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workOrder.orderNumber,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusLabel(workOrder.status),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _statusColor(workOrder.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(workOrder.createdAt),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'IN_PROGRESS':
        return 'Đang sửa';
      case 'WAITING_PARTS':
        return 'Chờ phụ tùng';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'PAID':
        return 'Đã thanh toán';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return Icons.build;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'WAITING_PARTS':
        return Icons.inventory_2;
      case 'PAID':
        return Icons.payments;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return AppColors.primary;
      case 'COMPLETED':
        return const Color(0xFF16A34A);
      case 'WAITING_PARTS':
        return const Color(0xFFF59E0B);
      case 'PAID':
        return const Color(0xFF0EA5E9);
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
}

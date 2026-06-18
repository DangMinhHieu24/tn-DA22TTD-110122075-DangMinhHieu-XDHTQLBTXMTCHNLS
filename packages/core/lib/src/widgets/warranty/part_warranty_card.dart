import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/warranty_model.dart';
import 'warranty_status_badge.dart';

class PartWarrantyCard extends StatelessWidget {
  final PartWarrantyModel partWarranty;

  const PartWarrantyCard({
    super.key,
    required this.partWarranty,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(partWarranty.status),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Part name and Status
            Row(
              children: [
                const Icon(
                  Icons.build,
                  size: 24,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    partWarranty.partName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                WarrantyStatusBadge(
                  status: partWarranty.status,
                  daysRemaining: partWarranty.daysRemaining,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Time Remaining
            _buildTimeRemainingRow(),

            const Divider(height: 24),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _buildDateInfo(
                    label: 'Ngày bắt đầu',
                    date: partWarranty.startDate,
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateInfo(
                    label: 'Ngày hết hạn',
                    date: partWarranty.expiryDate,
                    icon: Icons.event,
                    isExpiry: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Warranty days info
            _buildInfoRow(
              icon: Icons.timer_outlined,
              label: 'Thời hạn bảo hành',
              value: '${partWarranty.warrantyDays} ngày',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRemainingRow() {
    final daysText = partWarranty.daysRemaining < 0
        ? 'Đã hết hạn ${partWarranty.daysRemaining.abs()} ngày'
        : partWarranty.daysRemaining == 0
            ? 'Hết hạn hôm nay'
            : partWarranty.daysRemaining == 1
                ? 'Còn 1 ngày'
                : 'Còn ${partWarranty.daysRemaining} ngày';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTimeRemainingBgColor(partWarranty.status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 20,
            color: _getIconColor(partWarranty.status),
          ),
          const SizedBox(width: 8),
          Text(
            daysText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getIconColor(partWarranty.status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo({
    required String label,
    required DateTime date,
    required IconData icon,
    bool isExpiry = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('dd/MM/yyyy').format(date),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isExpiry && partWarranty.status == WarrantyStatus.expired
                ? const Color(0xFFDC2626)
                : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getBorderColor(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return const Color(0xFF86EFAC);
      case WarrantyStatus.expiringSoon:
        return const Color(0xFFFCD34D);
      case WarrantyStatus.expired:
        return const Color(0xFFFCA5A5);
    }
  }

  Color _getIconColor(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return const Color(0xFF166534);
      case WarrantyStatus.expiringSoon:
        return const Color(0xFF92400E);
      case WarrantyStatus.expired:
        return const Color(0xFF991B1B);
    }
  }

  Color _getTimeRemainingBgColor(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return const Color(0xFFF0FDF4);
      case WarrantyStatus.expiringSoon:
        return const Color(0xFFFFFBEB);
      case WarrantyStatus.expired:
        return const Color(0xFFFEF2F2);
    }
  }
}

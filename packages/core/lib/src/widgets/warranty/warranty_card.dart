import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/warranty_model.dart';
import 'warranty_status_badge.dart';

class WarrantyCard extends StatelessWidget {
  final WarrantyModel warranty;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const WarrantyCard({
    super.key,
    required this.warranty,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(warranty.status),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Type and Status
              Row(
                children: [
                  Icon(
                    _getWarrantyIcon(warranty.warrantyType),
                    size: 24,
                    color: _getIconColor(warranty.status),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warranty.warrantyType,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  WarrantyStatusBadge(
                    status: warranty.status,
                    daysRemaining: warranty.daysRemaining,
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
                      date: warranty.startDate,
                      icon: Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateInfo(
                      label: 'Ngày hết hạn',
                      date: warranty.expiryDate,
                      icon: Icons.event,
                      isExpiry: true,
                    ),
                  ),
                ],
              ),

              // Issued By
              if (warranty.issuedBy != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.business,
                  label: 'Đơn vị cấp',
                  value: warranty.issuedBy!,
                ),
              ],

              // Terms
              if (warranty.terms != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.description_outlined,
                  label: 'Điều khoản',
                  value: warranty.terms!,
                ),
              ],

              // Action buttons for admin
              if (showActions && (onEdit != null || onDelete != null)) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Sửa'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                        ),
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Xóa'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRemainingRow() {
    final daysText = warranty.daysRemaining < 0
        ? 'Đã hết hạn ${warranty.daysRemaining.abs()} ngày'
        : warranty.daysRemaining == 0
            ? 'Hết hạn hôm nay'
            : warranty.daysRemaining == 1
                ? 'Còn 1 ngày'
                : 'Còn ${warranty.daysRemaining} ngày';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTimeRemainingBgColor(warranty.status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 20,
            color: _getIconColor(warranty.status),
          ),
          const SizedBox(width: 8),
          Text(
            daysText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getIconColor(warranty.status),
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
            color: isExpiry && warranty.status == WarrantyStatus.expired
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

  IconData _getWarrantyIcon(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('pin') || lowerType.contains('battery')) {
      return Icons.battery_charging_full;
    } else if (lowerType.contains('động cơ') || lowerType.contains('motor')) {
      return Icons.settings;
    } else if (lowerType.contains('khung') || lowerType.contains('frame')) {
      return Icons.directions_bike;
    }
    return Icons.verified_user;
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

import 'package:flutter/material.dart';
import '../../models/warranty_model.dart';

class WarrantyStatusBadge extends StatelessWidget {
  final WarrantyStatus status;
  final int daysRemaining;

  const WarrantyStatusBadge({
    super.key,
    required this.status,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status, daysRemaining);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 16,
            color: config.textColor,
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(WarrantyStatus status, int daysRemaining) {
    switch (status) {
      case WarrantyStatus.active:
        return _StatusConfig(
          label: 'Còn hiệu lực',
          icon: Icons.check_circle,
          backgroundColor: const Color(0xFFDCFCE7),
          borderColor: const Color(0xFF86EFAC),
          textColor: const Color(0xFF166534),
        );
      case WarrantyStatus.expiringSoon:
        return _StatusConfig(
          label: 'Sắp hết hạn',
          icon: Icons.warning_amber_rounded,
          backgroundColor: const Color(0xFFFEF3C7),
          borderColor: const Color(0xFFFCD34D),
          textColor: const Color(0xFF92400E),
        );
      case WarrantyStatus.expired:
        return _StatusConfig(
          label: 'Hết hạn',
          icon: Icons.cancel,
          backgroundColor: const Color(0xFFFEE2E2),
          borderColor: const Color(0xFFFCA5A5),
          textColor: const Color(0xFF991B1B),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  _StatusConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}

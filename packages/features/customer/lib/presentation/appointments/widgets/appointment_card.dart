import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/customer_appointment.dart';

class AppointmentCard extends StatelessWidget {
  final CustomerAppointment appointment;
  final VoidCallback? onCancel;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MM', 'vi').format(appointment.scheduledAt);
    final day = DateFormat('dd').format(appointment.scheduledAt);
    final weekday = _weekdayLabel(appointment.scheduledAt.weekday);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _getBorderColor()),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Date column ──
          Column(
            children: [
              Text(
                weekday,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                day,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                month,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // ── Vertical divider ──
          Container(
            width: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),

          const SizedBox(width: 14),

          // ── Right: Details ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + Cancel
                Row(
                  children: [
                    _buildStatusBadge(),
                    const Spacer(),
                    if (appointment.canCancel && onCancel != null)
                      GestureDetector(
                        onTap: () => _showCancelDialog(context),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Time
                Row(
                  children: [
                    Text(
                      DateFormat('HH:mm').format(appointment.scheduledAt),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Vehicle
                if (appointment.hasVehicle) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.two_wheeler,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${appointment.vehicleBrand ?? ''} ${appointment.vehicleModel ?? ''} • ${appointment.vehicleLicensePlate}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Service
                Row(
                  children: [
                    Icon(
                      _getServiceIcon(),
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      appointment.serviceTypeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Online badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.language,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LỊCH HẸN ONLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Notes
                if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    appointment.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String label;

    switch (appointment.status) {
      case 'CONFIRMED':
        bgColor = const Color(0xFF22C55E).withValues(alpha: 0.15);
        textColor = const Color(0xFF16A34A);
        label = 'ĐÃ XÁC NHẬN';
        break;
      case 'CANCELLED':
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
        textColor = const Color(0xFFDC2626);
        label = 'ĐÃ HỦY';
        break;
      default:
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        textColor = const Color(0xFFD97706);
        label = 'CHỜ XÁC NHẬN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (appointment.status) {
      case 'CONFIRMED':
        return const Color(0xFF22C55E).withValues(alpha: 0.3);
      case 'CANCELLED':
        return const Color(0xFFEF4444).withValues(alpha: 0.2);
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  IconData _getServiceIcon() {
    switch (appointment.serviceType) {
      case 'MAINTENANCE':
        return Icons.build_outlined;
      case 'BATTERY_CHECK':
        return Icons.battery_charging_full_outlined;
      case 'BRAKES_TIRES':
        return Icons.tire_repair;
      case 'OTHER_REPAIR':
        return Icons.handyman_outlined;
      default:
        return Icons.build_outlined;
    }
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case 1: return 'Th 2';
      case 2: return 'Th 3';
      case 3: return 'Th 4';
      case 4: return 'Th 5';
      case 5: return 'Th 6';
      case 6: return 'Th 7';
      case 7: return 'CN';
      default: return '';
    }
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

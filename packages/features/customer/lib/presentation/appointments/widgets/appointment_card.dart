import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/customer_appointment.dart';

class AppointmentCard extends StatelessWidget {
  final CustomerAppointment appointment;
  final VoidCallback? onCancel;
  final bool showTimeline;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onCancel,
    this.showTimeline = true,
  });

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('d').format(appointment.scheduledAt);
    final monthNames = [
      '', 'Th 1', 'Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6',
      'Th 7', 'Th 8', 'Th 9', 'Th 10', 'Th 11', 'Th 12'
    ];
    final monthLabel = monthNames[appointment.scheduledAt.month];
    final isCancelled = appointment.status == 'CANCELLED';
    final isPending = appointment.status == 'PENDING';
    final isConfirmed = appointment.status == 'CONFIRMED';

    Color statusColor;
    if (isCancelled) {
      statusColor = const Color(0xFF6D7B6C);
    } else if (isPending) {
      statusColor = const Color(0xFFBA1A1A);
    } else {
      statusColor = const Color(0xFF006E2F);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date column (.w-14)
            if (showTimeline)
              SizedBox(
                width: 56,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // bg-surface w-full py-2
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFFF7F9FB),
                      child: Column(
                        children: [
                          Text(
                            monthLabel,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF191C1E),
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPending
                            ? const Color(0xFFBA1A1A)
                            : isConfirmed
                                ? const Color(0xFF006E2F)
                                : const Color(0xFF6D7B6C),
                      ),
                    ),
                  ],
                ),
              ),

            if (showTimeline) const SizedBox(width: 24),

            // Card (.flex-1.deep-glass.rounded-lg.p-6)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006E2F).withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 0,
                      offset: const Offset(0, 1),
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPending
                                      ? const Color(0xFFBA1A1A)
                                      : isConfirmed
                                          ? const Color(0xFF006E2F)
                                          : const Color(0xFF6D7B6C),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                appointment.statusLabel.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (appointment.canCancel && onCancel != null)
                          GestureDetector(
                            onTap: () => _showCancelDialog(context),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Color(0xFF3D4A3D),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(appointment.scheduledAt),
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: showTimeline ? 36 : 28,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF191C1E),
                                height: 1,
                                letterSpacing: showTimeline ? -1.8 : -1.0,
                              ),
                            ),
                            if (!showTimeline) ...[
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('dd/MM/yyyy').format(appointment.scheduledAt),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3D4A3D),
                                ),
                              ),
                            ],
                            const SizedBox(width: 16),
                            Icon(
                              Icons.schedule_outlined,
                              size: showTimeline ? 32 : 24,
                              color: const Color(0xFF006E2F).withValues(alpha: 0.5),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Vehicle + Service
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (appointment.hasVehicle)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.two_wheeler,
                                      size: 20,
                                      color: Color(0xFF3D4A3D),
                                    ),
                                    const SizedBox(width: 12),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${appointment.vehicleBrand ?? ''} ${appointment.vehicleModel ?? ''}',
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF191C1E),
                                          ),
                                        ),
                                        TextSpan(
                                          text: '  |  ',
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w300,
                                            color: const Color(0xFF191C1E)
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        TextSpan(
                                          text: appointment.vehicleLicensePlate ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF3D4A3D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                  ],
                                ),
                              ),
                            Row(
                              children: [
                                Icon(
                                  _getServiceIcon(),
                                  size: 20,
                                  color: const Color(0xFF3D4A3D),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  appointment.serviceTypeLabel,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF191C1E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Footer
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      color: const Color(0xFF191C1E).withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.language,
                          size: 16,
                          color: Color(0xFF3D4A3D),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lịch hẹn online',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D4A3D),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Horizontal line (top-8 left-full w-4 h-px) connecting date → card
        if (showTimeline)
          Positioned(
            top: 32,
            left: 56,
            child: Container(
              width: 16,
              height: 1,
              color: statusColor.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }

  IconData _getServiceIcon() {
    switch (appointment.serviceType) {
      case 'MAINTENANCE':
        return Icons.build_outlined;
      case 'BATTERY_CHECK':
        return Icons.battery_charging_full_outlined;
      case 'BRAKES_TIRES':
        return Icons.tire_repair_outlined;
      case 'OTHER_REPAIR':
        return Icons.handyman_outlined;
      default:
        return Icons.build_outlined;
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );
  }
}

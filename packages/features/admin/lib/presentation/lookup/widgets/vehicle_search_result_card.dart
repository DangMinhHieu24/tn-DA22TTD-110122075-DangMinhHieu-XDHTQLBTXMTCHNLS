import 'package:flutter/material.dart';
import '../../../domain/entities/lookup_result.dart';

class VehicleSearchResultCard extends StatelessWidget {
  final VehicleLookupResult vehicle;
  final VoidCallback onTap;
  final int index;

  const VehicleSearchResultCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isWarranty = vehicle.isUnderWarranty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWarranty
                  ? const Color(0xFF006E2F).withValues(alpha: 0.12)
                  : const Color(0xFFECEEF0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isWarranty
                          ? [const Color(0xFF006E2F), const Color(0xFF22C55E)]
                          : [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)],
                    ),
                  ),
                ),
                // Vehicle icon
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isWarranty
                                  ? [
                                      const Color(0xFFE8F5E9),
                                      const Color(0xFFC8E6C9),
                                    ]
                                  : [
                                      const Color(0xFFF5F5F5),
                                      const Color(0xFFE0E0E0),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    vehicle.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.two_wheeler_rounded,
                                        color: isWarranty
                                            ? const Color(0xFF006E2F)
                                            : const Color(0xFF616161),
                                        size: 28,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.two_wheeler_rounded,
                                  color: isWarranty
                                      ? const Color(0xFF006E2F)
                                      : const Color(0xFF616161),
                                  size: 28,
                                ),
                        ),
                        const SizedBox(width: 14),
                        // Vehicle info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // License plate + warranty badge
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      vehicle.licensePlate,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF191C1E),
                                        letterSpacing: 0.5,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _WarrantyBadge(isActive: isWarranty),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Brand + model
                              Text(
                                vehicle.displayName.isEmpty
                                    ? 'Không rõ model'
                                    : vehicle.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Owner + year + color
                              Text(
                                _buildSubtitle(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isWarranty
                              ? const Color(0xFF006E2F).withValues(alpha: 0.4)
                              : const Color(0xFFBCCBB9),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (vehicle.ownerName != null) parts.add(vehicle.ownerName!);
    if (vehicle.color != null) parts.add(vehicle.color!);
    if (vehicle.manufactureYear != null) parts.add('${vehicle.manufactureYear}');
    if (vehicle.currentKm != null) parts.add('${vehicle.currentKm} km');
    return parts.join(' • ');
  }
}

class _WarrantyBadge extends StatelessWidget {
  final bool isActive;

  const _WarrantyBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'BH còn hạn' : 'Hết BH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFF15803D)
                  : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}

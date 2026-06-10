import 'package:flutter/material.dart';
import '../../../domain/entities/lookup_result.dart';

class VehicleSearchResultCard extends StatelessWidget {
  final VehicleLookupResult vehicle;
  final VoidCallback onTap;

  const VehicleSearchResultCard({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWarranty = vehicle.isUnderWarranty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECEEF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Vehicle icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                color: Color(0xFF455A64),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            // Vehicle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // License plate + warranty badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.licensePlate,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF191C1E),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isWarranty
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isWarranty
                                  ? Icons.verified_user_outlined
                                  : Icons.gpp_bad_outlined,
                              size: 12,
                              color: isWarranty
                                  ? const Color(0xFF006E2F)
                                  : const Color(0xFFBA1A1A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isWarranty ? 'Còn BH' : 'Hết BH',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isWarranty
                                    ? const Color(0xFF006E2F)
                                    : const Color(0xFFBA1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Brand + model
                  Text(
                    vehicle.displayName.isEmpty ? 'Không rõ model' : vehicle.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D4A3D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Owner + year + color
                  Text(
                    _buildSubtitle(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6D7B6C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBCCBB9),
              size: 20,
            ),
          ],
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

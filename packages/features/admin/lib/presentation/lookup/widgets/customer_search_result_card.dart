import 'package:flutter/material.dart';
import '../../../domain/entities/lookup_result.dart';

class CustomerSearchResultCard extends StatelessWidget {
  final CustomerLookupResult customer;
  final VoidCallback onTap;

  const CustomerSearchResultCard({
    super.key,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: customer.avatarUrl != null && customer.avatarUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(customer.avatarUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.person, color: Color(0xFF7B1FA2), size: 28),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF191C1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Phone / Email
                  if (customer.phoneNumber != null)
                    Text(
                      customer.phoneNumber!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3D4A3D),
                      ),
                    ),
                  if (customer.phoneNumber == null && customer.email != null)
                    Text(
                      customer.email!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6D7B6C),
                      ),
                    ),
                  const SizedBox(height: 3),
                  // Vehicle count + loyalty
                  Text(
                    _buildSubtitle(),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6D7B6C)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBCCBB9), size: 20),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    parts.add('${customer.vehicleCount} xe');
    if (customer.loyaltyPoints > 0) {
      parts.add('${customer.loyaltyPoints} điểm');
    }
    return parts.join(' • ');
  }
}
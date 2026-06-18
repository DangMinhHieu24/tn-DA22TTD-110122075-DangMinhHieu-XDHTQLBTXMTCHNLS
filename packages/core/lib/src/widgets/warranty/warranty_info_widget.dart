import 'package:flutter/material.dart';
import '../../models/warranty_model.dart';
import 'warranty_card.dart';
import 'part_warranty_card.dart';

class WarrantyInfoWidget extends StatelessWidget {
  final WarrantyResponse warrantyResponse;
  final bool showEditActions;
  final bool showVehicleInfo;
  final Function(WarrantyModel)? onEditWarranty;
  final Function(WarrantyModel)? onDeleteWarranty;
  final VoidCallback? onAddWarranty;
  final bool isLoading;

  const WarrantyInfoWidget({
    super.key,
    required this.warrantyResponse,
    this.showEditActions = false,
    this.showVehicleInfo = true,
    this.onEditWarranty,
    this.onDeleteWarranty,
    this.onAddWarranty,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF15803D),
        ),
      );
    }

    final vehicle = warrantyResponse.vehicle;
    final warranties = warrantyResponse.warranties;
    final partWarranties = warrantyResponse.partWarranties;
    final hasAny = warranties.isNotEmpty || partWarranties.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Info Section
          if (showVehicleInfo) _buildVehicleInfoSection(vehicle),

          // ── Empty state when both lists are empty ──
          if (!hasAny) _buildEmptyState(),

          // ── General Warranties ──
          if (warranties.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: Color(0xFF15803D),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Các loại bảo hành',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (showEditActions && onAddWarranty != null)
                    IconButton(
                      onPressed: onAddWarranty,
                      icon: const Icon(Icons.add_circle),
                      color: const Color(0xFF15803D),
                      tooltip: 'Thêm bảo hành mới',
                    ),
                ],
              ),
            ),
            ...warranties.map((warranty) => WarrantyCard(
                  warranty: warranty,
                  showActions: showEditActions,
                  onEdit: showEditActions && onEditWarranty != null
                      ? () => onEditWarranty!(warranty)
                      : null,
                  onDelete: showEditActions && onDeleteWarranty != null
                      ? () => onDeleteWarranty!(warranty)
                      : null,
                )),
          ],

          // ── Part Warranties ──
          if (partWarranties.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.build,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bảo hành phụ tùng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${partWarranties.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...partWarranties.map(
              (pw) => PartWarrantyCard(partWarranty: pw),
            ),
          ],

          // Warning Note
          if (warranties.any((w) => w.status == WarrantyStatus.expiringSoon) ||
              partWarranties.any((pw) => pw.status == WarrantyStatus.expiringSoon))
            _buildWarningNote(context),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoSection(VehicleWarrantyInfo vehicle) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0FDF4), // green-50
            Color(0xFFE0F2FE), // blue-50
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Vehicle Image
          if (vehicle.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                vehicle.imageUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
              ),
            )
          else
            _buildImagePlaceholder(),

          const SizedBox(width: 16),

          // Vehicle Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.licensePlate,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vehicle.brand ?? ''} ${vehicle.model}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4B5563),
                  ),
                ),
                if (vehicle.manufactureYear != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Năm sản xuất: ${vehicle.manufactureYear}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                if (vehicle.currentKm != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.speed,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${vehicle.currentKm!.toStringAsFixed(0)} km',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.two_wheeler,
        size: 40,
        color: Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có thông tin bảo hành',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Liên hệ với đơn vị bán xe để được hỗ trợ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningNote(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF92400E),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lưu ý quan trọng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Một số bảo hành sắp hết hạn. Hãy bảo trì định kỳ để giữ quyền bảo hành.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.brown[800],
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

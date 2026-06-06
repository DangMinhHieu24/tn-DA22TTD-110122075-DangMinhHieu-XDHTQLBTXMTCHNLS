import 'package:flutter/material.dart';
import '../../../data/models/vehicle_model.dart';

class AdminVehicleDetailSheet extends StatelessWidget {
  final VehicleModel vehicle;
  final ValueChanged<String> onIntakePressed;

  const AdminVehicleDetailSheet({
    super.key,
    required this.vehicle,
    required this.onIntakePressed,
  });

  static void show(BuildContext context, VehicleModel vehicle, ValueChanged<String> onIntakePressed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminVehicleDetailSheet(
        vehicle: vehicle,
        onIntakePressed: onIntakePressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFDBDEE0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header: Plate & Brand
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDBDEE0)),
                ),
                child: Text(
                  vehicle.licensePlate,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF191C1E),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.model,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF006E2F),
                      ),
                    ),
                    Text(
                      '${vehicle.brand ?? 'Không rõ hãng'} • ${vehicle.color ?? 'Không rõ màu'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3D4A3D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Customer Info
          const Text(
            'THÔNG TIN KHÁCH HÀNG',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6D7B6C),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFECEEF0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF006E2F)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.ownerName ?? 'Chưa cập nhật tên',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.ownerPhone ?? 'Chưa cập nhật SĐT',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3D4A3D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Vehicle Status
          const Text(
            'TRẠNG THÁI XE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6D7B6C),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.speed,
                  label: 'Số KM',
                  value: vehicle.currentKm != null ? '${vehicle.currentKm} km' : '--',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.verified_user_outlined,
                  label: 'Bảo hành',
                  value: vehicle.isUnderWarranty ? 'Còn hạn' : 'Hết hạn',
                  valueColor: vehicle.isUnderWarranty ? const Color(0xFF006E2F) : const Color(0xFFBA1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close sheet
                onIntakePressed(vehicle.licensePlate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006E2F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tạo Phiếu Tiếp Nhận',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECEEF0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6D7B6C)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6D7B6C),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF191C1E),
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

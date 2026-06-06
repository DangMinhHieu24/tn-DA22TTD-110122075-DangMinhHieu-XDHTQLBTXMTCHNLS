import 'package:flutter/material.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/datasources/remote/vehicle_remote_datasource.dart';
import 'admin_vehicle_detail_sheet.dart';

class CustomerVehiclesSheet extends StatelessWidget {
  final CustomerWithVehicles customer;
  final ValueChanged<String> onIntakePressed;

  const CustomerVehiclesSheet({
    super.key,
    required this.customer,
    required this.onIntakePressed,
  });

  static void show(BuildContext context, CustomerWithVehicles customer, ValueChanged<String> onIntakePressed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerVehiclesSheet(
        customer: customer,
        onIntakePressed: onIntakePressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(0, 12, 0, MediaQuery.of(context).padding.bottom + 20),
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF006E2F), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      Text(
                        customer.phoneNumber ?? 'Không có số điện thoại',
                        style: const TextStyle(
                          fontSize: 15,
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

          // Vehicle List Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'XE CỦA KHÁCH HÀNG',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6D7B6C),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Vehicle List
          if (customer.vehicles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Khách hàng chưa có xe nào trong hệ thống.',
                style: TextStyle(color: Color(0xFF3D4A3D), fontStyle: FontStyle.italic),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: customer.vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final vehicle = customer.vehicles[index];
                  // We need to inject the customer info back into the vehicle object
                  // since the API might not include the full owner object inside the array 
                  // to save space, but our VehicleModel needs it.
                  final completeVehicle = VehicleModel(
                    id: vehicle.id,
                    licensePlate: vehicle.licensePlate,
                    brand: vehicle.brand,
                    model: vehicle.model,
                    color: vehicle.color,
                    imageUrl: vehicle.imageUrl,
                    manufactureYear: vehicle.manufactureYear,
                    qrCode: vehicle.qrCode,
                    warrantyExpiry: vehicle.warrantyExpiry,
                    currentKm: vehicle.currentKm,
                    ownerId: customer.id,
                    ownerName: customer.name,
                    ownerPhone: customer.phoneNumber,
                    createdAt: vehicle.createdAt,
                  );

                  return _buildVehicleCard(context, completeVehicle);
                },
              ),
            ),

          const SizedBox(height: 24),

          // CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  onIntakePressed(''); // Add new vehicle flow
                },
                icon: const Icon(Icons.add, color: Color(0xFF006E2F)),
                label: const Text(
                  'Thêm Xe Mới & Tiếp Nhận',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF006E2F),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleModel vehicle) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close this sheet
        // Open the single vehicle detail sheet
        AdminVehicleDetailSheet.show(context, vehicle, onIntakePressed);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECEEF0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191C1E).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                image: vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(vehicle.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: vehicle.imageUrl == null || vehicle.imageUrl!.isEmpty
                  ? const Icon(Icons.two_wheeler_rounded, color: Color(0xFF3D4A3D))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.licensePlate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vehicle.brand ?? 'Không rõ'} • ${vehicle.model}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3D4A3D),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBCCBB9)),
          ],
        ),
      ),
    );
  }
}

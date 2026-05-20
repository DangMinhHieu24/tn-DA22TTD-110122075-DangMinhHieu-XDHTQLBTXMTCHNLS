import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class UrgentWorkCard extends StatelessWidget {
  final String licensePlate;
  final String vehicleModel;
  final String customerName;
  final String description;
  final VoidCallback? onStartRepair;

  const UrgentWorkCard({
    super.key,
    required this.licensePlate,
    required this.vehicleModel,
    required this.customerName,
    required this.description,
    this.onStartRepair,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onStartRepair,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.tertiaryFixed,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.black.withOpacity(0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: AppColors.tertiaryFixed.withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.onTertiaryFixed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'XỬ LÝ GẤP',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.tertiaryFixed,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        licensePlate,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.onTertiaryFixed,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$vehicleModel • $customerName',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onTertiaryFixed.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.electric_moped,
                      color: AppColors.onTertiaryFixed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onTertiaryFixed,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onStartRepair,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.onTertiaryFixed,
                  foregroundColor: AppColors.tertiaryFixed,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Bắt đầu sửa chữa',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

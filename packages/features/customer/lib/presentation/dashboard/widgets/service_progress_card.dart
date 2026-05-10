import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class ServiceProgressCard extends StatelessWidget {
  const ServiceProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = ['Tiếp nhận', 'Kiểm tra', 'Đang sửa', 'Thanh toán', 'Hoàn thành'];
    const activeStep = 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiến độ dịch vụ',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: activeStep / (steps.length - 1),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(steps.length, (index) {
                        final isDone = index < activeStep;
                        final isActive = index == activeStep;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isActive ? 32 : 26,
                              height: isActive ? 32 : 26,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppColors.primary
                                    : isActive
                                        ? AppColors.primaryContainer
                                        : AppColors.surfaceContainerHigh,
                                shape: BoxShape.circle,
                                border: isActive
                                    ? Border.all(
                                        color: AppColors.surfaceContainerLowest,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: Icon(
                                isDone
                                    ? Icons.check
                                    : isActive
                                        ? Icons.build
                                        : Icons.circle,
                                size: 14,
                                color: isDone
                                    ? Colors.white
                                    : isActive
                                        ? AppColors.onPrimaryContainer
                                        : AppColors.onSurfaceVariant.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 56,
                              height: 28,
                              child: Text(
                                steps[index],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 10,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.electric_bike, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VinFast Theon S',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Biển số: 29A1-123.45',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: AppColors.primaryContainer,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.security, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Còn bảo hành: 245 ngày',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Hẹn trả:',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '17:00',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class WorkStatusTimelineCard extends StatelessWidget {
  final String title;
  final int activeStep;

  const WorkStatusTimelineCard({
    super.key,
    required this.title,
    required this.activeStep,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedActiveStep = activeStep.clamp(0, 3);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const stepCount = 4;
              const stepRadius = 18.0;
              final trackWidth = constraints.maxWidth - stepRadius * 2;
              final progressWidth = trackWidth * (normalizedActiveStep / (stepCount - 1));

              return Stack(
                children: [
                  Positioned(
                    left: stepRadius,
                    right: stepRadius,
                    top: 17,
                    child: Container(
                      height: 2,
                      color: const Color(0xFFBCCBB9).withValues(alpha: 0.3),
                    ),
                  ),
                  Positioned(
                    left: stepRadius,
                    top: 17,
                    child: Container(
                      width: progressWidth,
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF006E2F), Color(0xFF22C55E)],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStep('Tiếp nhận', 0, normalizedActiveStep),
                      _buildStep('Kiểm tra', 1, normalizedActiveStep),
                      _buildStep('Đang sửa', 2, normalizedActiveStep),
                      _buildStep('Hoàn thành', 3, normalizedActiveStep),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String label, int step, int activeStep) {
    final isDone = step < activeStep;
    final isActive = step == activeStep;

    return SizedBox(
      width: 56,
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F4F6),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isActive && !isDone)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFBFC7C2),
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (isActive)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC9D2CC),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (isActive)
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0E7A3D),
                      shape: BoxShape.circle,
                    ),
                  ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF22C55E)
                        : isDone
                            ? const Color(0xFF006E2F)
                            : const Color(0xFFF2F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone
                        ? Icons.check
                        : (isActive ? Icons.build : Icons.flag_outlined),
                    size: 12,
                    color: isActive
                        ? const Color(0xFF0B3B20)
                        : (isDone ? Colors.white : const Color(0xFF3D4A3D)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isActive || isDone
                  ? const Color(0xFF006E2F)
                  : AppColors.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class StatsCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;
  final Color backgroundColor;
  final bool isHighlighted;

  const StatsCard({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: AppColors.primary.withOpacity(0.1))
            : null,
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.onSurface.withOpacity(0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? AppColors.primaryContainer.withOpacity(0.2)
                      : AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Text(
                count,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

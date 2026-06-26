import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class TechChatSuggestions extends StatelessWidget {
  final ValueChanged<String> onTap;

  const TechChatSuggestions({super.key, required this.onTap});

  static const _suggestions = [
    _SuggestionItem(icon: Icons.directions_car_rounded, label: 'Tra cứu biển số'),
    _SuggestionItem(icon: Icons.inventory_2_rounded, label: 'Kiểm tra tồn kho'),
    _SuggestionItem(icon: Icons.receipt_long_rounded, label: 'Tra phiếu sửa chữa'),
    _SuggestionItem(icon: Icons.shield_outlined, label: 'Bảo hành xe'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.onSurface.withValues(alpha: 0.04),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 14, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                'Gợi ý nhanh',
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              return ActionChip(
                avatar: Icon(s.icon, size: 16, color: const Color(0xFF006E2F)),
                label: Text(
                  s.label,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF191C1E),
                  ),
                ),
                onPressed: () => onTap(s.label),
                backgroundColor: const Color(0xFFF0F4F1),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionItem {
  final IconData icon;
  final String label;
  const _SuggestionItem({required this.icon, required this.label});
}

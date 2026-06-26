import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class ChatSuggestions extends StatelessWidget {
  final ValueChanged<String> onTap;

  const ChatSuggestions({super.key, required this.onTap});

  static const suggestions = [
    'Có những dịch vụ gì?',
    'Bảo dưỡng định kỳ',
    'Báo giá sửa chữa',
    'Địa chỉ cửa hàng',
    'Chính sách bảo hành',
    'Điểm thưởng & cây xanh',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Gợi ý nhanh',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return ActionChip(
                label: Text(
                  s,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
                onPressed: () => onTap(s),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class ChatSuggestions extends StatelessWidget {
  final ValueChanged<String> onTap;
  final List<String>? customSuggestions;

  const ChatSuggestions({
    super.key,
    required this.onTap,
    this.customSuggestions,
  });

  static const defaultSuggestions = [
    'Có những dịch vụ gì?',
    'Bảo dưỡng định kỳ',
    'Báo giá sửa chữa',
    'Địa chỉ cửa hàng',
    'Chính sách bảo hành',
    'Điểm thưởng & cây xanh',
  ];

  @override
  Widget build(BuildContext context) {
    final list = customSuggestions ?? defaultSuggestions;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 3.5,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Gợi ý nhanh cho bạn',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list.map((s) {
              return InkWell(
                onTap: () => onTap(s),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    s,
                    style: AppTextStyles.labelMedium.copyWith(
                       fontSize: 11.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

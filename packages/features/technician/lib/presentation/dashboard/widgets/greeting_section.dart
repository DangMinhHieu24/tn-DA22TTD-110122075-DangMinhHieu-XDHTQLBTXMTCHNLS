import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart';

class GreetingSection extends StatelessWidget {
  final TextEditingController searchController;
  final String userName;

  const GreetingSection({
    super.key,
    required this.searchController,
    this.userName = 'Tuấn Anh',
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, dd MMMM, yyyy', 'vi');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateFormat.format(now),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            children: [
              const TextSpan(text: 'Chào buổi sáng, '),
              TextSpan(
                text: userName,
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Tìm biển số, khách hàng...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant.withOpacity(0.6),
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.onSurfaceVariant,
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary.withOpacity(0.4),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

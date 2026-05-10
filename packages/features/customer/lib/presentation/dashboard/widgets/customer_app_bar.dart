import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class CustomerAppBar extends StatelessWidget {
  const CustomerAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuD6IeHhIFn6wWDaa4PtK7ZlZmbX-PJYvPHxupEDXVg2i17i_6CPAov2Zidei7a6fO7pRbyB6AWQoyzGJYjOQlKTWo0qYOOFCUk_xTITzSJcN_-puLgB9NPX_K7iIfOaWHHEQtXUuQfKw8K35zOgqII5PDcKMtd8NVkjPGB-3pv_DwvwqZZ6uCUEvGg-5zgCy2myYWc7PfFnQjF1WHaIlWS2E-qDa7jlGSTnyIwmP8mTI6SIKAqjvdQnrDFhQZon1pMjqwCvqrwdhCQ',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào,',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Nguyễn Văn A',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

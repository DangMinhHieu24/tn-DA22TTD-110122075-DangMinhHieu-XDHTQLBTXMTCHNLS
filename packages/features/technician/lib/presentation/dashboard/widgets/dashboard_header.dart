import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';

class DashboardHeader extends StatelessWidget {
  final String userInitials;
  final VoidCallback? onNotificationTap;

  const DashboardHeader({
    super.key,
    this.userInitials = 'TA',
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F4F6),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        userInitials,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Service Portal',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              NotificationBellIcon(onTap: onNotificationTap),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class ProfileLogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const ProfileLogoutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout, size: 20, color: AppColors.error),
        label: const Text(
          'Đăng xuất tài khoản',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.errorContainer, width: 1.2),
          backgroundColor: const Color(0xFFFFF0ED),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import '../../domain/entities/user.dart';

class UserAvatar extends StatelessWidget {
  final User user;
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryContainer,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: user.avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  user.avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildInitials();
                  },
                ),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    final initials = _getInitials(user.name);
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

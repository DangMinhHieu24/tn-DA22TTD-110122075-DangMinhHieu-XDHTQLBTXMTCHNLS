import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class SettingsItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class ProfileSettingsSection extends StatelessWidget {
  final List<SettingsItem> items;

  const ProfileSettingsSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: List.generate(items.length * 2 - 1, (index) {
            if (index.isOdd) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: Color(0xFFF0F2F4)),
              );
            }
            final i = index ~/ 2;
            return _buildTile(items[i]);
          }),
        ),
      ),
    );
  }

  Widget _buildTile(SettingsItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 20, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: AppColors.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}

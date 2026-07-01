import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class CustomerBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  const CustomerBottomNav({
    super.key,
    required this.selectedIndex,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFF006E2F).withValues(alpha: 0.22),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF006E2F).withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: SizedBox(
            height: 52,
            child: Stack(
              children: [
                // Premium Sliding Capsule Background
                AnimatedAlign(
                  alignment: Alignment(
                    selectedIndex == 0
                        ? -1.0
                        : selectedIndex == 1
                            ? 0.0
                            : 1.0,
                    0.0,
                  ),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic,
                  child: FractionallySizedBox(
                    widthFactor: 1 / 3,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF006E2F),
                            Color(0xFF22C55E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF006E2F).withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Interactive Tab items
                Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: Icons.electric_bike_outlined,
                        activeIcon: Icons.electric_bike,
                        label: 'XE CỦA TÔI',
                        isSelected: selectedIndex == 0,
                        onTap: () => onItemSelected?.call(0),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.calendar_month_outlined,
                        activeIcon: Icons.calendar_month,
                        label: 'ĐẶT LỊCH',
                        isSelected: selectedIndex == 1,
                        onTap: () => onItemSelected?.call(1),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'TÀI KHOẢN',
                        isSelected: selectedIndex == 2,
                        onTap: () => onItemSelected?.call(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Smooth elastic scale effect on select
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 200),
                tween: ColorTween(
                  end: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                ),
                builder: (context, color, child) {
                  return Icon(
                    isSelected ? activeIcon : icon,
                    color: color,
                    size: 20,
                  );
                },
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

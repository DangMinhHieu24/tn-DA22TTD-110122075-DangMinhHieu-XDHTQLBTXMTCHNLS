import 'package:flutter/material.dart';

/// Service Checkbox Widget - Checkbox card for service selection
class ServiceCheckbox extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const ServiceCheckbox({
    super.key,
    required this.icon,
    required this.label,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F6), // surface-container-low
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isChecked ? const Color(0xFF006E2F) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isChecked ? const Color(0xFF006E2F) : const Color(0xFF3D4A3D),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF191C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

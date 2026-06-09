import 'package:flutter/material.dart';

/// Entity representing a category in the lookup radial menu.
class LookupCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const LookupCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookupCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

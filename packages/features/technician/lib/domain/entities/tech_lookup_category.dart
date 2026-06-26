import 'package:flutter/material.dart';

class TechLookupCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const TechLookupCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

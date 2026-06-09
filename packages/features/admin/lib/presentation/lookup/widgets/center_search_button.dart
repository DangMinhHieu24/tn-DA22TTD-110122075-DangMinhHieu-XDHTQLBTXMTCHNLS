import 'package:flutter/material.dart';

class CenterSearchButton extends StatelessWidget {
  final double radius;
  final bool isDragging;
  final double pulseValue;

  const CenterSearchButton({
    super.key,
    required this.radius,
    required this.isDragging,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final scale = isDragging ? 0.92 : pulseValue;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFF4ADE80),
              Color(0xFF22C55E),
              Color(0xFF16A34A),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF16A34A).withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.search,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Draws a line from the center of the widget to either the current drag
/// position or the hovered category icon, with a gradient and rounded ends.
class ConnectingLinePainter extends CustomPainter {
  final Offset dragOffset;
  final int hoveredIndex;
  final Offset? categoryOffset;
  final Color color;

  ConnectingLinePainter({
    required this.dragOffset,
    required this.hoveredIndex,
    this.categoryOffset,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final end = center + (categoryOffset ?? dragOffset);

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromPoints(center, end))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center, end, paint);

    // Draw a small dot at the end
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(end, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant ConnectingLinePainter oldDelegate) {
    return dragOffset != oldDelegate.dragOffset ||
        hoveredIndex != oldDelegate.hoveredIndex;
  }
}

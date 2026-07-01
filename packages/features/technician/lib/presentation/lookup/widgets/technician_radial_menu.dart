import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/tech_lookup_category.dart';

class TechnicianRadialMenu extends StatefulWidget {
  final List<TechLookupCategory> categories;
  final ValueChanged<TechLookupCategory> onCategorySelected;

  const TechnicianRadialMenu({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<TechnicianRadialMenu> createState() => _TechnicianRadialMenuState();
}

class _TechnicianRadialMenuState extends State<TechnicianRadialMenu>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _glowController;
  late final AnimationController _entryController;

  late final Animation<double> _pulseAnimation;
  late final Animation<double> _glowAnimation;

  int _hoveredIndex = -1;
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;

  static const double _centerRadius = 44.0;
  static const double _categoryRadius = 32.0;
  static const double _orbitRadius = 125.0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_glowController);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  double _angleFor(int index) {
    const startAngle = -math.pi / 2;
    return startAngle +
        (2 * math.pi * index / widget.categories.length);
  }

  Offset _categoryOffset(int index) {
    final angle = _angleFor(index);
    return Offset(
      _orbitRadius * math.cos(angle),
      _orbitRadius * math.sin(angle),
    );
  }

  int _hitTest(Offset localDrag) {
    for (int i = 0; i < widget.categories.length; i++) {
      final catOffset = _categoryOffset(i);
      final distance = (localDrag - catOffset).distance;
      if (distance < _categoryRadius + 20) return i;
    }
    return -1;
  }

  void _onCategoryTapped(int index) {
    if (index < 0 || index >= widget.categories.length) return;
    HapticFeedback.mediumImpact();
    widget.onCategorySelected(widget.categories[index]);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation, _entryController]),
      builder: (context, _) => _buildRadialMenu(),
    );
  }

  Widget _buildRadialMenu() {
    const size = (_orbitRadius + _categoryRadius + 40) * 2;
    return Transform.translate(
      offset: Offset.zero,
      child: SizedBox(
        width: size,
        height: size,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            final center = Offset(size / 2, size / 2);
            final rel = d.localPosition - center;
            if (rel.distance < _centerRadius + 20) {
              setState(() {
                _isDragging = true;
                _dragOffset = rel;
                _hoveredIndex = _hitTest(rel);
              });
              HapticFeedback.lightImpact();
            }
          },
          onPanUpdate: (d) {
            if (!_isDragging) return;
            final center = Offset(size / 2, size / 2);
            final rel = d.localPosition - center;
            final newHovered = _hitTest(rel);
            if (newHovered != _hoveredIndex && newHovered >= 0) {
              HapticFeedback.selectionClick();
            }
            setState(() {
              _dragOffset = rel;
              _hoveredIndex = newHovered;
            });
          },
          onPanEnd: (_) {
            if (_isDragging && _hoveredIndex >= 0) {
              _onCategoryTapped(_hoveredIndex);
            }
            setState(() {
              _isDragging = false;
              _hoveredIndex = -1;
              _dragOffset = Offset.zero;
            });
          },
          onPanCancel: () {
            setState(() {
              _isDragging = false;
              _hoveredIndex = -1;
              _dragOffset = Offset.zero;
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              ..._buildGlowRings(),
              if (_isDragging) _buildConnectingLine(),
              ..._buildCategoryIcons(),
              Positioned(
                left: (_orbitRadius + _categoryRadius + 40) - _centerRadius,
                top: (_orbitRadius + _categoryRadius + 40) - _centerRadius,
                child: _buildCenterButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGlowRings() {
    final rings = <Widget>[];
    const ringRadii = [_centerRadius + 16, _centerRadius + 34];
    final center = _orbitRadius + _categoryRadius + 40;

    for (final r in ringRadii) {
      rings.add(Positioned(
        left: center - r,
        top: center - r,
        child: Container(
          width: r * 2,
          height: r * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
        ),
      ));
    }

    rings.add(Positioned(
      left: center - ringRadii[1],
      top: center - ringRadii[1],
      child: Transform.rotate(
        angle: _glowAnimation.value * 2 * math.pi,
        child: SizedBox(
          width: ringRadii[1] * 2,
          height: ringRadii[1] * 2,
          child: CustomPaint(
            painter: _ArcPainter(
              color: const Color(0xFF006E2F),
              strokeWidth: 2,
              arcSweep: math.pi * 0.35,
            ),
          ),
        ),
      ),
    ));

    return rings;
  }

  Widget _buildConnectingLine() {
    return CustomPaint(
      size: Size(
        (_orbitRadius + _categoryRadius + 40) * 2,
        (_orbitRadius + _categoryRadius + 40) * 2,
      ),
      painter: _ConnectingLinePainter(
        dragOffset: _dragOffset,
        categoryOffset:
            _hoveredIndex >= 0 ? _categoryOffset(_hoveredIndex) : null,
        color: _hoveredIndex >= 0
            ? widget.categories[_hoveredIndex].color
            : const Color(0xFF22C55E),
      ),
    );
  }

  List<Widget> _buildCategoryIcons() {
    const labelWidth = 110.0;
    return List.generate(widget.categories.length, (i) {
      final cat = widget.categories[i];
      final offset = _categoryOffset(i);
      final isHovered = _hoveredIndex == i;

      final entryDelay = i / widget.categories.length;
      final entryProgress = Curves.elasticOut.transform(
        ((_entryController.value - entryDelay) / (1 - entryDelay))
            .clamp(0.0, 1.0),
      );

      final scale = isHovered ? 1.2 : 1.0;
      final iconSize = isHovered ? 28.0 : 24.0;
      final isTop = i == 0;

      return Positioned(
        left: (_orbitRadius + _categoryRadius + 40) + offset.dx - labelWidth / 2,
        top: isTop
            ? (_orbitRadius + _categoryRadius + 40) + offset.dy - _categoryRadius - 26
            : (_orbitRadius + _categoryRadius + 40) + offset.dy - _categoryRadius,
        child: Transform.scale(
          scale: entryProgress * scale,
          child: GestureDetector(
            onTap: () => _onCategoryTapped(i),
            child: SizedBox(
              width: labelWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isTop) ...[
                    _buildLabelWidget(cat, isHovered),
                    const SizedBox(height: 8),
                  ],
                  _buildIconWidget(cat, isHovered, iconSize),
                  if (!isTop) ...[
                    const SizedBox(height: 8),
                    _buildLabelWidget(cat, isHovered),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLabelWidget(TechLookupCategory cat, bool isHovered) {
    return SizedBox(
      width: 110,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isHovered ? 13 : 11.5,
          fontWeight: isHovered ? FontWeight.w700 : FontWeight.w600,
          color: isHovered ? cat.color : const Color(0xFF3D4A3D),
          letterSpacing: 0.2,
          height: 1.2,
        ),
        child: Text(cat.label),
      ),
    );
  }

  Widget _buildIconWidget(TechLookupCategory cat, bool isHovered, double iconSize) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: _categoryRadius * 2,
      height: _categoryRadius * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(cat.bgColor, cat.color, isHovered ? 0.7 : 0.0)!,
            Color.lerp(cat.bgColor, cat.color, isHovered ? 1.0 : 0.15)!,
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: cat.color.withValues(alpha: isHovered ? 0.6 : 0.2),
          width: isHovered ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isHovered)
            BoxShadow(
              color: cat.color.withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: cat.color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Icon(
        cat.icon,
        color: isHovered ? Colors.white : cat.color,
        size: iconSize,
      ),
    );
  }

  Widget _buildCenterButton() {
    final scale = _isDragging ? 0.92 : _pulseAnimation.value;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: _centerRadius * 2,
        height: _centerRadius * 2,
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
        child: const Icon(Icons.search, color: Colors.white, size: 32),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double arcSweep;

  _ArcPainter({
    required this.color,
    this.strokeWidth = 2,
    this.arcSweep = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      arcSweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.arcSweep != arcSweep || old.color != color;
}

class _ConnectingLinePainter extends CustomPainter {
  final Offset dragOffset;
  final Offset? categoryOffset;
  final Color color;

  _ConnectingLinePainter({
    required this.dragOffset,
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

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(end, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ConnectingLinePainter oldDelegate) {
    return dragOffset != oldDelegate.dragOffset ||
        categoryOffset != oldDelegate.categoryOffset;
  }
}

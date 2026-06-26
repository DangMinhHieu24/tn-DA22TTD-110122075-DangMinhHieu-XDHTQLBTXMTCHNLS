import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/lookup_category.dart';
import '../bloc/lookup_bloc.dart';
import '../pages/vehicle_lookup_page.dart';
import '../pages/customer_lookup_page.dart';
import '../pages/invoice_lookup_page.dart';
import '../pages/warranty_lookup_page.dart';
import '../../dashboard/pages/inventory_page.dart';
import '../../dashboard/pages/work_order_list_page.dart';
import 'connecting_line_painter.dart';
import 'center_search_button.dart';

class RadialLookupMenu extends StatefulWidget {
  final List<LookupCategory> categories;

  const RadialLookupMenu({
    super.key,
    required this.categories,
  });

  @override
  State<RadialLookupMenu> createState() => _RadialLookupMenuState();
}

class _RadialLookupMenuState extends State<RadialLookupMenu>
    with TickerProviderStateMixin {
  // ───────────────────────── Animation controllers ─────────────────────────
  late final AnimationController _pulseController;
  late final AnimationController _glowController;
  late final AnimationController _categoryScaleController;
  late final AnimationController _lineController;
  late final AnimationController _entryController;

  late final Animation<double> _pulseAnimation;
  late final Animation<double> _glowAnimation;

  // ───────────────────────── Drag state ─────────────────────────
  int _hoveredIndex = -1;
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;

  // ───────────────────────── Layout constants ─────────────────────────
  static const double _centerRadius = 44.0;
  static const double _categoryRadius = 32.0;
  static const double _orbitRadius = 142.0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_glowController);

    _categoryScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _categoryScaleController.dispose();
    _lineController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  double _angleFor(int index) {
    const startAngle = -math.pi / 2; // top
    return startAngle + (2 * math.pi * index / widget.categories.length);
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

  void _onCategorySelected(int index) {
    if (index < 0 || index >= widget.categories.length) return;
    HapticFeedback.mediumImpact();
    final cat = widget.categories[index];

    final bloc = context.read<LookupBloc>();

    Widget page;
    switch (cat.id) {
      case 'warranty':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WarrantyLookupPage()),
        );
        return;
      case 'vehicle':
        page = const VehicleLookupPage();
      case 'customer':
        page = const CustomerLookupPage();
      case 'part':
        // InventoryPage needs its own bloc, don't navigate with LookupBloc
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InventoryPage()),
        );
        return;
      case 'invoice':
        page = const InvoiceLookupPage();
      case 'work_order':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WorkOrderListPage()),
        );
        return;
      default:
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(cat.icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Tra cứu ${cat.label} — Sắp có',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: cat.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => BlocProvider.value(
          value: bloc,
          child: page,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _glowAnimation,
        _entryController,
      ]),
      builder: (context, _) => _buildRadialMenu(),
    );
  }

  Widget _buildRadialMenu() {
    const size = (_orbitRadius + _categoryRadius + 40) * 2;
    return Transform.translate(
      offset: const Offset(-6, 0),
      child: SizedBox(
        width: size,
        height: size,
        child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          final center = const Offset(size / 2, size / 2);
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
          final center = const Offset(size / 2, size / 2);
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
            _onCategorySelected(_hoveredIndex);
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
            // Glow rings
            ..._buildGlowRings(),
            // Connecting line
            if (_isDragging) _buildConnectingLine(),
            // Category icons
            ..._buildCategoryIcons(),
            // Center button
            CenterSearchButton(
              radius: _centerRadius,
              isDragging: _isDragging,
              pulseValue: _pulseAnimation.value,
            ),
          ],
        ),
      ),
    ),
    );
  }

  List<Widget> _buildGlowRings() {
    // 2 vòng tròn tĩnh
    final rings = <Widget>[];
    final ringRadii = [
      _centerRadius + 18,         // vòng trong
      _centerRadius + 38,         // vòng ngoài
    ];
    for (final r in ringRadii) {
      rings.add(
        Container(
          width: r * 2,
          height: r * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
        ),
      );
    }

    // Arc 1 — chạy vòng ngoài
    rings.add(
      Transform.rotate(
        angle: _glowAnimation.value * 2 * math.pi,
        child: SizedBox(
          width: ringRadii[1] * 2,
          height: ringRadii[1] * 2,
          child: CustomPaint(
            painter: _ArcPainter(
              color: const Color(0xFF006E2F),
              strokeWidth: 2.5,
              arcSweep: math.pi * 0.4,
            ),
          ),
        ),
      ),
    );

    // Arc 2 — chạy vòng trong, ngược chiều
    rings.add(
      Transform.rotate(
        angle: -_glowAnimation.value * 2 * math.pi,
        child: SizedBox(
          width: ringRadii[0] * 2,
          height: ringRadii[0] * 2,
          child: CustomPaint(
            painter: _ArcPainter(
              color: const Color(0xFF15803D),
              strokeWidth: 2.0,
              arcSweep: math.pi * 0.35,
            ),
          ),
        ),
      ),
    );

    return rings;
  }

  Widget _buildConnectingLine() {
    return CustomPaint(
      size: const Size(
        (_orbitRadius + _categoryRadius + 40) * 2,
        (_orbitRadius + _categoryRadius + 40) * 2,
      ),
      painter: ConnectingLinePainter(
        dragOffset: _dragOffset,
        hoveredIndex: _hoveredIndex,
        categoryOffset: _hoveredIndex >= 0 ? _categoryOffset(_hoveredIndex) : null,
        color: _hoveredIndex >= 0
            ? widget.categories[_hoveredIndex].color
            : const Color(0xFF22C55E),
      ),
    );
  }

  List<Widget> _buildCategoryIcons() {
    const labelWidth = 80.0;
    return List.generate(widget.categories.length, (i) {
      final cat = widget.categories[i];
      final offset = _categoryOffset(i);
      final isHovered = _hoveredIndex == i;

      final entryDelay = i / widget.categories.length;
      final entryProgress = Curves.elasticOut.transform(
        ((_entryController.value - entryDelay) / (1 - entryDelay)).clamp(0.0, 1.0),
      );

      final scale = isHovered ? 1.2 : 1.0;
      final iconSize = isHovered ? 30.0 : 26.0;
      final halfItem = labelWidth / 2;
      const halfIcon = _categoryRadius; // 32

      return Positioned(
        left: (_orbitRadius + _categoryRadius + 40) + offset.dx - halfItem,
        top: (_orbitRadius + _categoryRadius + 40) + offset.dy - halfIcon,
        child: Transform.scale(
          scale: entryProgress * scale,
          child: GestureDetector(
            onTap: () => _onCategorySelected(i),
            child: SizedBox(
              width: labelWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ─── Icon card with gradient & shadow ───
                  AnimatedContainer(
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
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 6,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      cat.icon,
                      key: ValueKey('${i}_$isHovered'),
                      color: isHovered ? Colors.white : cat.color,
                      size: iconSize,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // ─── Label (fixed width để text luôn căn giữa, không lệch) ───
                SizedBox(
                  width: 80,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isHovered ? 13 : 11.5,
                      fontWeight: isHovered ? FontWeight.w700 : FontWeight.w600,
                      color: isHovered ? cat.color : const Color(0xFF3D4A3D),
                      letterSpacing: 0.2,
                      height: 1.2,
                      shadows: isHovered
                          ? [Shadow(color: cat.color.withValues(alpha: 0.3), blurRadius: 6)]
                          : null,
                    ),
                    child: Text(cat.label),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      );
    });
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double arcSweep;

  _ArcPainter({
    required this.color,
    this.strokeWidth = 2.5,
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
  bool shouldRepaint(covariant _ArcPainter old) => old.arcSweep != arcSweep || old.color != color;
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/service_station.dart';

const kToken = ''; // TODO: add Mapbox token

final kTileUrl =
    'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}?access_token=$kToken';
const kAttribution = '';
const kSubdomains = <String>[];

class StationMarker extends StatefulWidget {
  final ServiceStation station;
  final bool isSelected;
  final VoidCallback? onTap;

  const StationMarker({
    super.key,
    required this.station,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<StationMarker> createState() => _StationMarkerState();
}

class _StationMarkerState extends State<StationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounce = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    if (widget.isSelected) _ctrl.forward();
  }

  @override
  void didUpdateWidget(StationMarker old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isSelected ? 54.0 : 44.0;

    final pin = SizedBox(
      width: size + 16,
      height: size * 1.35 + 4,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (widget.isSelected)
            Positioned(
              top: 2,
              child: Container(
                width: size + 4,
                height: size + 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF006E2F).withValues(alpha: 0.15),
                  border: Border.all(
                    color: const Color(0xFF006E2F).withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
              ),
            ),
          CustomPaint(
            size: Size(size, size * 1.35),
            painter: _PinPainter(isSelected: widget.isSelected),
          ),
          Positioned(
            top: size / 2 - 10,
            child: Icon(
              Icons.ev_station_rounded,
              color: widget.isSelected ? Colors.white : const Color(0xFF006E2F),
              size: widget.isSelected ? 24 : 20,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: widget.isSelected
          ? AnimatedBuilder(
              animation: _bounce,
              builder: (_, __) => Transform.scale(
                scale: 0.9 + 0.1 * _bounce.value,
                child: pin,
              ),
            )
          : pin,
    );
  }
}

class _PinPainter extends CustomPainter {
  final bool isSelected;
  _PinPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final path = ui.Path()
      ..moveTo(0, r)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..lineTo(size.width / 2, size.height)
      ..close();

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = isSelected
            ? ui.Gradient.linear(
                Offset(0, 0),
                Offset(0, size.height),
                [const Color(0xFF008B3A), const Color(0xFF005C26)],
              )
            : null
        ..color = isSelected ? const Color(0xFF006E2F) : Colors.white,
    );

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF006E2F),
    );

    // Inner accent ring
    canvas.drawCircle(
      Offset(size.width / 2, r),
      r * 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = isSelected
            ? Colors.white.withValues(alpha: 0.25)
            : const Color(0xFF006E2F).withValues(alpha: 0.15),
    );

    // Shadow at bottom
    final shadowPath = ui.Path()
      ..moveTo(size.width * 0.15, size.height - 2)
      ..lineTo(size.width * 0.85, size.height - 2)
      ..lineTo(size.width * 0.65, size.height - 6)
      ..lineTo(size.width * 0.35, size.height - 6)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..color = Colors.black.withValues(alpha: 0.15),
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) =>
      old.isSelected != isSelected;
}

class UserMarker extends StatefulWidget {
  const UserMarker({super.key});

  @override
  State<UserMarker> createState() => _UserMarkerState();
}

class _UserMarkerState extends State<UserMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulseOuter;
  late final Animation<double> _pulseInner;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseOuter = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _pulseInner = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseOuter,
            builder: (_, __) => Container(
              width: 22 * _pulseOuter.value,
              height: 22 * _pulseOuter.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _pulseInner,
            builder: (_, __) => Container(
              width: 16 * _pulseInner.value,
              height: 16 * _pulseInner.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A73E8).withValues(alpha: 0.18),
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Marker> buildStationMarkers({
  required List<ServiceStation> stations,
  required String? selectedStationId,
  required void Function(ServiceStation) onStationTap,
}) {
  return stations.map((s) {
    return Marker(
      point: s.location,
      width: 70,
      height: 85,
      child: StationMarker(
        station: s,
        isSelected: selectedStationId == s.id,
        onTap: () => onStationTap(s),
      ),
    );
  }).toList();
}

Marker? buildUserMarker(LatLng? userLocation) {
  if (userLocation == null) return null;
  return Marker(
    point: userLocation,
    width: 56,
    height: 56,
    child: const UserMarker(),
  );
}

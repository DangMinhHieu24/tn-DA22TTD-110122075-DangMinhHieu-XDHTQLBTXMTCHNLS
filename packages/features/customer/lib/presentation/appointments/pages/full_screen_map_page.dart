import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/service_station.dart';
import '../widgets/map_markers.dart';

class FullScreenMapPage extends StatefulWidget {
  final List<ServiceStation> stations;
  final LatLng? userLocation;
  final ServiceStation? initialStation;

  const FullScreenMapPage({
    super.key,
    required this.stations,
    this.userLocation,
    this.initialStation,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  final MapController _mapController = MapController();
  final Distance _distance = Distance();
  late ServiceStation? _selectedStation;
  String? _distanceText;

  @override
  void initState() {
    super.initState();
    _selectedStation = widget.initialStation;
    _updateDistance();
  }

  void _updateDistance() {
    if (_selectedStation != null && widget.userLocation != null) {
      final d = _distance(widget.userLocation!, _selectedStation!.location);
      _distanceText = 'Cách đây ${(d / 1000).toStringAsFixed(1)} km';
    }
  }

  void _selectStation(ServiceStation station) {
    setState(() {
      _selectedStation = station;
      if (widget.userLocation != null) {
        final d = _distance(widget.userLocation!, station.location);
        _distanceText = 'Cách đây ${(d / 1000).toStringAsFixed(1)} km';
      }
    });
    _mapController.move(station.location, 14);
  }

  void _openDirections() {
    if (_selectedStation == null) return;
    final lat = _selectedStation!.location.latitude;
    final lng = _selectedStation!.location.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final center = _selectedStation?.location ??
        widget.userLocation ??
        const LatLng(9.9328, 106.3353);

    return Scaffold(
      backgroundColor: const Color(0xFF2D3A2D),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              minZoom: 10,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (_, latlng) {
                ServiceStation? nearest;
                double minDist = double.infinity;
                for (final s in widget.stations) {
                  final d = _distance(latlng, s.location);
                  if (d < minDist) {
                    minDist = d;
                    nearest = s;
                  }
                }
                if (nearest != null) {
                  _selectStation(nearest);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: kTileUrl,
                subdomains: kSubdomains,
                tileSize: 256,
                userAgentPackageName: 'com.nanglungsach.app',
              ),
              PolylineLayer(
                polylines: [
                  if (widget.userLocation != null && _selectedStation != null)
                    Polyline(
                      points: [widget.userLocation!, _selectedStation!.location],
                      color: const Color(0xFF006E2F).withValues(alpha: 0.35),
                      strokeWidth: 2,
                      pattern: const StrokePattern.dotted(),
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  ...buildStationMarkers(
                    stations: widget.stations,
                    selectedStationId: _selectedStation?.id,
                    onStationTap: _selectStation,
                  ),
                  if (buildUserMarker(widget.userLocation) case final userMarker?)
                    userMarker,
                ],
              ),
            ],
          ),
          // Gradient overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Deep-glass overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006E2F).withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedStation?.name ?? 'Trạm Dịch Vụ EV',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.near_me,
                              size: 16,
                              color: Color(0xFF3D4A3D),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _distanceText ?? 'Đang xác định...',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3D4A3D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _openDirections,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF006E2F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF191C1E),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

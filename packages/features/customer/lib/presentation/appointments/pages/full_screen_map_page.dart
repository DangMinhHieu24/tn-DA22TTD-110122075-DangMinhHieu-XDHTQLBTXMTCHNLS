import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/service_station.dart';
import '../data/routing_service.dart';
import '../widgets/map_markers.dart';

class FullScreenMapPage extends StatefulWidget {
  final List<ServiceStation> stations;
  final LatLng? userLocation;
  final ServiceStation? initialStation;
  final List<LatLng> initialRoutePoints;
  final String? initialDistanceText;

  const FullScreenMapPage({
    super.key,
    required this.stations,
    this.userLocation,
    this.initialStation,
    this.initialRoutePoints = const [],
    this.initialDistanceText,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();
  late ServiceStation? _selectedStation;
  String? _distanceText;
  final RoutingService _routingService = RoutingService();
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _selectedStation = widget.initialStation;
    _routePoints = List.from(widget.initialRoutePoints);
    _distanceText = widget.initialDistanceText;
    if (_distanceText == null) {
      _updateDistance();
    }
  }

  void _updateDistance() {
    if (_selectedStation != null && widget.userLocation != null) {
      final d = _distance(widget.userLocation!, _selectedStation!.location);
      _distanceText = 'Cách đây ${(d / 1000).toStringAsFixed(1)} km';
    }
  }

  Future<void> _updateRoute() async {
    if (widget.userLocation == null || _selectedStation == null) return;
    try {
      final routeInfo = await _routingService.getRoute(
        widget.userLocation!,
        _selectedStation!.location,
      );
      
      final distKm = (routeInfo.distance / 1000).toStringAsFixed(1);
      final durMin = (routeInfo.duration / 60).round();
      
      setState(() {
        _routePoints = routeInfo.points;
        _distanceText = '$distKm km • $durMin phút';
      });
    } catch (_) {
      final d = _distance(widget.userLocation!, _selectedStation!.location);
      setState(() {
        _routePoints = [widget.userLocation!, _selectedStation!.location];
        _distanceText = 'Cách đây ${(d / 1000).toStringAsFixed(1)} km';
      });
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      if (_selectedStation != null && widget.userLocation != null) {
        final d = _distance(widget.userLocation!, _selectedStation!.location);
        _distanceText = 'Cách đây ${(d / 1000).toStringAsFixed(1)} km';
      }
    });
  }

  void _selectStation(ServiceStation station) {
    setState(() {
      _selectedStation = station;
    });
    _mapController.move(station.location, 14);
    _updateRoute();
  }

  void _openDirections() {
    if (_selectedStation == null) return;
    final lat = _selectedStation!.location.latitude;
    final lng = _selectedStation!.location.longitude;
    
    final String urlString;
    if (widget.userLocation != null) {
      urlString = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${widget.userLocation!.latitude},${widget.userLocation!.longitude}'
          '&destination=$lat,$lng';
    } else {
      urlString = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    }
    
    final url = Uri.parse(urlString);
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
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF006E2F),
                      strokeWidth: 4,
                      borderColor: const Color(0xFF004D20),
                      borderStrokeWidth: 1,
                    )
                  else if (widget.userLocation != null && _selectedStation != null)
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF191C1E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.near_me,
                                  size: 14,
                                  color: Color(0xFF3D4A3D),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _distanceText ?? 'Đang xác định...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3D4A3D),
                                    fontSize: 13,
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF008B3A), Color(0xFF006E2F)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF006E2F).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Dẫn đường',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context, {
                'selectedStation': _selectedStation,
                'routePoints': _routePoints,
                'distanceText': _distanceText,
              }),
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
          // Clear route button (floating on top right)
          if (_routePoints.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: GestureDetector(
                onTap: _clearRoute,
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
                    Icons.close,
                    color: Color(0xFFBA1A1A),
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

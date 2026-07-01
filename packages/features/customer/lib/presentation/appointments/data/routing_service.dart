import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class RouteInfo {
  final List<LatLng> points;
  final double distance; // in meters
  final double duration; // in seconds

  RouteInfo({
    required this.points,
    required this.distance,
    required this.duration,
  });
}

class RoutingService {
  final Dio _dio = Dio();

  Future<RouteInfo> getRoute(LatLng start, LatLng end) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';
      
      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data['code'] == 'Ok') {
        final routes = response.data['routes'] as List;
        if (routes.isNotEmpty) {
          final route = routes.first;
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;
          
          final points = coordinates.map((coord) {
            final lng = (coord[0] as num).toDouble();
            final lat = (coord[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();
          
          final distance = (route['distance'] as num).toDouble();
          final duration = (route['duration'] as num).toDouble();

          return RouteInfo(
            points: points,
            distance: distance,
            duration: duration,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching route from OSRM: $e');
    }
    
    const distanceCalculator = Distance();
    final double fallbackDistance = distanceCalculator(start, end);
    final double fallbackDuration = fallbackDistance / 8.33; // 30 km/h in m/s

    return RouteInfo(
      points: [start, end],
      distance: fallbackDistance,
      duration: fallbackDuration,
    );
  }
}

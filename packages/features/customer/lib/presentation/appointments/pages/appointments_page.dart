import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../vehicles/widgets/customer_app_bar.dart';
import '../../vehicles/widgets/customer_bottom_nav.dart';
import '../../vehicles/pages/my_vehicles_page.dart';
import '../../account/pages/customer_account_page.dart';
import '../../chat/widgets/chat_floating_bubble.dart';
import '../bloc/appointment_bloc.dart';
import '../widgets/appointment_card.dart';
import '../../../domain/entities/customer_appointment.dart';
import '../data/service_station.dart';
import '../data/routing_service.dart';
import 'create_appointment_page.dart';
import 'full_screen_map_page.dart';
import '../widgets/map_markers.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late final AppointmentBloc _appointmentBloc;
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();
  LatLng? _userLocation;
  ServiceStation? _selectedStation;
  String? _distanceText;
  bool _isLoadingLocation = true;
  List<ServiceStation> _stations = [];
  final RoutingService _routingService = RoutingService();
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _appointmentBloc = GetIt.instance<AppointmentBloc>();
    _appointmentBloc.add(LoadAppointments());
    _stations = List.from(mockStations);
    _selectedStation = _stations.isNotEmpty ? _stations.first : null;
    _initLocation();
  }

  Future<void> _initLocation() async {
    LatLng userLoc;
    bool isFallback = false;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Dịch vụ định vị chưa bật');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Chưa cấp quyền truy cập vị trí');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Quyền truy cập vị trí đã bị từ chối vĩnh viễn');
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        userLoc = LatLng(pos.latitude, pos.longitude);
      } catch (_) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        );
        userLoc = LatLng(pos.latitude, pos.longitude);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      userLoc = const LatLng(9.92345, 106.34652);
      isFallback = true;
    }

    final nearest = mockStations.first;
    final minDist = _distance(userLoc, nearest.location);
    
    setState(() {
      _userLocation = userLoc;
      _stations = List.from(mockStations);
      _selectedStation = nearest;
      _distanceText = 'Cách đây ${(minDist / 1000).toStringAsFixed(1)} km';
      _isLoadingLocation = false;
    });
  }

  Future<void> _updateRoute() async {
    if (_userLocation == null || _selectedStation == null) return;
    try {
      final routeInfo = await _routingService.getRoute(
        _userLocation!,
        _selectedStation!.location,
      );
      
      final distKm = (routeInfo.distance / 1000).toStringAsFixed(1);
      final durMin = (routeInfo.duration / 60).round();
      
      setState(() {
        _routePoints = routeInfo.points;
        _distanceText = '$distKm km • $durMin phút';
      });
    } catch (_) {
      final d = _distance(_userLocation!, _selectedStation!.location);
      setState(() {
        _routePoints = [_userLocation!, _selectedStation!.location];
        _distanceText = 'Cách đây ${(d / 1000).toStringAsFixed(1)} km';
      });
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      if (_selectedStation != null && _userLocation != null) {
        final d = _distance(_userLocation!, _selectedStation!.location);
        _distanceText = 'Cách đây ${(d / 1000).toStringAsFixed(1)} km';
      }
    });
  }

  @override
  void dispose() {
    _appointmentBloc.close();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _appointmentBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 0.8,
              colors: [
                Color(0xFF006E2F),
                Color(0xFFF7F9FB),
              ],
              stops: [0.0, 0.6],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const CustomerAppBar(backgroundColor: Colors.transparent),
                Expanded(
                  child: BlocConsumer<AppointmentBloc, AppointmentState>(
                    listener: (context, state) {
                      if (state is AppointmentCreated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đặt lịch hẹn thành công!'),
                            backgroundColor: const Color(0xFF22C55E),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                      if (state is AppointmentCancelled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã hủy lịch hẹn'),
                            backgroundColor: AppColors.onSurfaceVariant,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                      if (state is AppointmentHistoryCleared) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã xoá lịch sử lịch hẹn'),
                            backgroundColor: const Color(0xFF22C55E),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                      if (state is AppointmentError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          _appointmentBloc.add(LoadAppointments());
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 672),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 24),

                                    // Map section
                                    _buildMapSection(),

                                    const SizedBox(height: 32),

                                    // Book appointment
                                    _buildNewAppointmentButton(context),

                                    const SizedBox(height: 32),

                                    // Appointments list
                                    _buildAppointmentsList(state),

                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Map section ────────────────────────────────────────────────
  Widget _buildMapSection() {
    final center = _selectedStation?.location ??
        _userLocation ??
        const LatLng(9.9328, 106.3353);

    return GestureDetector(
      onTap: _openFullScreenMap,
      child: Container(
      height: 288,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006E2F).withValues(alpha: 0.16),
            blurRadius: 36,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
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
                for (final s in _stations) {
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
                  else if (_userLocation != null && _selectedStation != null)
                    Polyline(
                      points: [_userLocation!, _selectedStation!.location],
                      color: const Color(0xFF006E2F).withValues(alpha: 0.35),
                      strokeWidth: 2,
                      pattern: const StrokePattern.dotted(),
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  ...buildStationMarkers(
                    stations: _stations,
                    selectedStationId: _selectedStation?.id,
                    onStationTap: _selectStation,
                  ),
                  if (buildUserMarker(_userLocation) case final userMarker?)
                    userMarker,
                  if (_isLoadingLocation)
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF006E2F),
                        ),
                      ),
                    ),
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
          // Expand button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _openFullScreenMap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Color(0xFF191C1E),
                  size: 20,
                ),
              ),
            ),
          ),
          // Clear route button (floating)
          if (_routePoints.isNotEmpty)
            Positioned(
              top: 52,
              right: 8,
              child: GestureDetector(
                onTap: _clearRoute,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
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
          // Deep-glass overlay with station info
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
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
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF3D4A3D),
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
          // Border overlay for premium finish
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF006E2F).withValues(alpha: 0.25),
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _openFullScreenMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenMapPage(
          stations: _stations,
          userLocation: _userLocation,
          initialStation: _selectedStation,
          initialRoutePoints: _routePoints,
          initialDistanceText: _distanceText,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedStation = result['selectedStation'] as ServiceStation?;
        _routePoints = List<LatLng>.from(result['routePoints'] as Iterable);
        _distanceText = result['distanceText'] as String?;
      });
      if (_selectedStation != null) {
        _mapController.move(_selectedStation!.location, 14);
      }
    }
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
    if (_userLocation != null) {
      urlString = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${_userLocation!.latitude},${_userLocation!.longitude}'
          '&destination=$lat,$lng';
    } else {
      urlString = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    }
    
    final url = Uri.parse(urlString);
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ─── Book appointment ───────────────────────────────────────────
  Widget _buildNewAppointmentButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCreatePage(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF006E2F).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đặt lịch mới',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sắp xếp thời gian bảo dưỡng',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3D4A3D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Appointments list ──────────────────────────────────────────
  Widget _buildAppointmentsList(AppointmentState state) {
    if (state is AppointmentLoading || state is AppointmentInitial) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is AppointmentError) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Không thể tải lịch hẹn',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _appointmentBloc.add(LoadAppointments()),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final List<CustomerAppointment> appointments =
        state is AppointmentLoaded ? state.appointments : [];

    if (appointments.isEmpty) {
      return _buildEmptyState();
    }

    final List<CustomerAppointment> upcoming = appointments
        .where((a) => a.isUpcoming)
        .toList();
    final List<CustomerAppointment> past = appointments
        .where((a) => !a.isUpcoming)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    final recentPast = past.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (upcoming.isNotEmpty) ...[
          _buildSectionHeader(
            'Lịch trình',
            upcoming.length,
            onTap: () =>
                _showAllAppointments('Lịch trình', upcoming, canCancel: true),
          ),
          const SizedBox(height: 6),
          _buildTimelineList(upcoming, canCancel: true),
        ],

        if (recentPast.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSectionHeader(
            'Đã qua',
            past.length,
            onTap: () => _showAllAppointments('Đã qua', past),
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: 0.65,
            child: _buildTimelineList(recentPast),
          ),
        ],
      ],
    );
  }

  Widget _buildTimelineList(
    List<CustomerAppointment> items, {
    bool canCancel = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Vertical timeline gradient line (matching left-[4.5rem] = 72px)
        Positioned(
          left: 72,
          top: 40,
          bottom: 0,
          child: Container(
            width: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF006E2F).withValues(alpha: 0.3),
                  const Color(0xFF6D7B6C).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Cards
        Column(
          children: items.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == items.length - 1 ? 0 : 24,
              ),
              child: AppointmentCard(
                appointment: entry.value,
                onCancel: canCancel && entry.value.canCancel
                    ? () => _appointmentBloc
                        .add(CancelExistingAppointment(entry.value.id))
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF191C1E),
              letterSpacing: -0.6,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Xem tất cả',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF006E2F),
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllAppointments(String title, List<CustomerAppointment> items,
      {bool canCancel = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFBCCBB9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF191C1E),
                    ),
                  ),
                  const Spacer(),
                  if (title == 'Đã qua' && items.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _showClearHistoryConfirm();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline,
                                size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text(
                              'Xoá tất cả',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: Color(0xFF3D4A3D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => AppointmentCard(
                    appointment: items[i],
                    showTimeline: false,
                    onCancel: canCancel && items[i].canCancel
                        ? () {
                            Navigator.of(ctx).pop();
                            _appointmentBloc
                                .add(CancelExistingAppointment(items[i].id));
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearHistoryConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Xoá lịch sử'),
        content: const Text('Bạn có chắc muốn xoá tất cả lịch hẹn đã qua?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _appointmentBloc.add(ClearAppointmentHistory());
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có lịch hẹn nào',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn "Đặt lịch mới" để đặt lịch bảo dưỡng',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D4A3D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreatePage(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _appointmentBloc,
          child: const CreateAppointmentPage(),
        ),
      ),
    );
    if (result == true) {
      _appointmentBloc.add(LoadAppointments());
    }
  }

}

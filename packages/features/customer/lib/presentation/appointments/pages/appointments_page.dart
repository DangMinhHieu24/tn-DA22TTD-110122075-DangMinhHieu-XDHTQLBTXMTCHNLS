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
  final Distance _distance = Distance();
  LatLng? _userLocation;
  ServiceStation? _selectedStation;
  String? _distanceText;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _appointmentBloc = GetIt.instance<AppointmentBloc>();
    _appointmentBloc.add(LoadAppointments());
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final userLoc = LatLng(pos.latitude, pos.longitude);
      ServiceStation nearest = mockStations.first;
      double minDist = double.infinity;
      for (final s in mockStations) {
        final d = _distance(userLoc, s.location);
        if (d < minDist) {
          minDist = d;
          nearest = s;
        }
      }
      setState(() {
        _userLocation = userLoc;
        _selectedStation = nearest;
        _distanceText = 'Cách đây ${(minDist / 1000).toStringAsFixed(1)} km';
        _isLoadingLocation = false;
      });
    } catch (_) {
      setState(() => _isLoadingLocation = false);
    }
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
            child: Stack(
              children: [
                Column(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 0,
                              ),
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
              CustomerBottomNav(
                selectedIndex: 1,
                onItemSelected: (index) => _handleNavigation(context, index),
              ),
            ],
          ),
          const ChatFloatingBubble(),
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
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006E2F).withValues(alpha: 0.1),
            blurRadius: 50,
            offset: const Offset(0, 25),
            spreadRadius: -12,
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
                for (final s in mockStations) {
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
                  if (_userLocation != null && _selectedStation != null)
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
                    stations: mockStations,
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
          // Deep-glass overlay with station info
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
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
                      children: [
                        Text(
                          _selectedStation?.name ?? 'Trạm Dịch Vụ EV',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF191C1E),
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
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3D4A3D),
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
        ],
      ),
      ),
    );
  }

  void _openFullScreenMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenMapPage(
          stations: mockStations,
          userLocation: _userLocation,
          initialStation: _selectedStation,
        ),
      ),
    );
  }

  void _selectStation(ServiceStation station) {
    setState(() {
      _selectedStation = station;
      if (_userLocation != null) {
        final d = _distance(_userLocation!, station.location);
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

  void _handleNavigation(BuildContext context, int index) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyVehiclesPage()),
      );
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerAccountPage()),
      );
    }
  }
}

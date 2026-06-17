import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';
import 'package:intl/intl.dart';
import '../../../data/datasources/remote/vehicle_remote_datasource.dart';
import '../../../domain/entities/admin_appointment.dart';
import '../../../domain/usecases/delete_appointment.dart';
import '../bloc/admin_appointment_bloc.dart';
import '../bloc/admin_appointment_event.dart';
import '../bloc/admin_appointment_state.dart';
import '../widgets/admin_vehicle_detail_sheet.dart';
import '../widgets/customer_vehicles_sheet.dart';
import 'vehicle_intake_page.dart';

/// Reception Hub Page
/// Trang trung tâm tiếp nhận - xuất hiện trước khi vào form tiếp nhận xe mới
/// Cho phép: tìm xe theo biển số / SĐT, quét QR, xem khách sắp đến
class ReceptionHubPage extends StatefulWidget {
  const ReceptionHubPage({super.key});

  @override
  State<ReceptionHubPage> createState() => _ReceptionHubPageState();
}

enum _AppointmentFilter { today, upcoming, all }

class _ReceptionHubPageState extends State<ReceptionHubPage>
    with SingleTickerProviderStateMixin {
  int _searchTab = 0; // 0 = biển số, 1 = SĐT
  final _searchController = TextEditingController();
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  bool _isSearching = false;
  _AppointmentFilter _appointmentFilter = _AppointmentFilter.upcoming;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = GetIt.instance<AdminAppointmentBloc>();
        bloc.add(_buildAppointmentEvent());
        return bloc;
      },
      child: FadeTransition(
        opacity: _fadeIn,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F9FB),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Search section ──────────────────────────────
                        _buildSearchSection(),
                        const SizedBox(height: 20),
                        // ── QR Scan Card ────────────────────────────────
                        _buildQRScanCard(),
                        const SizedBox(height: 28),
                        // ── Upcoming customers ──────────────────────────
                        _buildUpcomingSection(),
                        const SizedBox(height: 100), // space above FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Floating CTA ─────────────────────────────────────────────
          bottomNavigationBar: _buildBottomCTA(),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Search Section
  // ────────────────────────────────────────────────────────────────────
  Widget _buildSearchSection() {
    return Column(
      children: [
        // Tab switcher: Biển số | Số điện thoại
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFECEEF0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildSearchTab('Biển số', 0),
              _buildSearchTab('Số điện thoại', 1),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Search input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFBCCBB9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                _searchTab == 0
                    ? Icons.two_wheeler_rounded
                    : Icons.phone_rounded,
                color: const Color(0xFF6D7B6C),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  keyboardType: _searchTab == 0
                      ? TextInputType.text
                      : TextInputType.phone,
                  inputFormatters: _searchTab == 0
                      ? [UpperCaseTextFormatter()]
                      : [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191C1E),
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: _searchTab == 0
                        ? 'Nhập biển số xe (VD: 29A-1)'
                        : 'Nhập số điện thoại khách',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              // Search button
              GestureDetector(
                onTap: _isSearching ? null : _performSearch,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isSearching ? const Color(0xFFBCCBB9) : const Color(0xFF006E2F),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _isSearching ? null : [
                      BoxShadow(
                        color: const Color(0xFF006E2F).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isSearching 
                      ? const Center(
                          child: SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(
                              color: Colors.white, 
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchTab(String label, int index) {
    final isSelected = _searchTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _searchTab = index;
            _searchController.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF006E2F)
                    : const Color(0xFF6D7B6C),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // QR Scan Card
  // ────────────────────────────────────────────────────────────────────
  Widget _buildQRScanCard() {
    return GestureDetector(
      onTap: _openQRScanner,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF006E2F).withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // QR icon badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF006E2F),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006E2F).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quét mã định danh QR',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF191C1E),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Truy xuất nhanh thông tin xe & lịch sử',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF3D4A3D),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Upcoming Customers Section
  // ────────────────────────────────────────────────────────────────────
  String get _sectionTitle {
    switch (_appointmentFilter) {
      case _AppointmentFilter.today:
        return 'Hôm nay';
      case _AppointmentFilter.upcoming:
        return 'Sắp tới (7 ngày tới)';
      case _AppointmentFilter.all:
        return 'Tất cả lịch hẹn';
    }
  }

  LoadUpcomingAppointments _buildAppointmentEvent() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    switch (_appointmentFilter) {
      case _AppointmentFilter.today:
        return LoadUpcomingAppointments(date: today);
      case _AppointmentFilter.upcoming:
        final nextWeek = DateFormat('yyyy-MM-dd')
            .format(DateTime.now().add(const Duration(days: 7)));
        // dateFrom = hôm nay, dateTo = 7 ngày tới
        return LoadUpcomingAppointments(dateFrom: today, dateTo: nextWeek);
      case _AppointmentFilter.all:
        return LoadUpcomingAppointments();
    }
  }

  Widget _buildUpcomingSection() {
    const filterLabels = ['Hôm nay', 'Sắp tới', 'Tất cả'];
    final currentIndex = _AppointmentFilter.values.indexOf(_appointmentFilter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _sectionTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF191C1E),
                letterSpacing: -0.3,
              ),
            ),
            PopupMenuButton<int>(
              onSelected: (value) {
                if (value != currentIndex) {
                  setState(() => _appointmentFilter = _AppointmentFilter.values[value]);
                  context.read<AdminAppointmentBloc>().add(_buildAppointmentEvent());
                }
              },
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                for (var i = 0; i < filterLabels.length; i++)
                  PopupMenuItem<int>(
                    value: i,
                    child: Row(
                      children: [
                        Text(
                          filterLabels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: currentIndex == i ? FontWeight.w700 : FontWeight.w400,
                            color: currentIndex == i
                                ? const Color(0xFF006E2F)
                                : const Color(0xFF191C1E),
                          ),
                        ),
                        if (currentIndex == i) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check, size: 16, color: Color(0xFF006E2F)),
                        ],
                      ],
                    ),
                  ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEEF0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filterLabels[currentIndex],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF006E2F),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: Color(0xFF006E2F),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Customer cards from BLoC
        BlocBuilder<AdminAppointmentBloc, AdminAppointmentState>(
          builder: (context, state) {
            if (state is AdminAppointmentLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is AdminAppointmentError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Không thể tải lịch hẹn',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFBA1A1A),
                    ),
                  ),
                ),
              );
            }

            final appointments = state is AdminAppointmentLoaded
                ? state.appointments
                : <AdminAppointment>[];

            if (appointments.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 40,
                        color: Color(0xFFBCCBB9),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Chưa có lịch hẹn nào',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3D4A3D),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: appointments.map((appointment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSwipeableCard(appointment),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(AdminAppointment appointment) {
    final isPending = appointment.isPending;
    final timeStr = DateFormat('HH:mm').format(appointment.scheduledAt);
    final isToday = _isSameDay(appointment.scheduledAt, DateTime.now());
    final hasVehicle = appointment.vehicleLicensePlate != null;

    return GestureDetector(
      onTap: () => _openAppointmentDetails(appointment),
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPending
                ? const Color(0xFF006E2F).withValues(alpha: 0.2)
                : const Color(0xFFBCCBB9).withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Customer icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFECEEF0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  hasVehicle ? Icons.electric_bike_rounded : Icons.person_rounded,
                  color: Color(0xFF006E2F),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appointment.customerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF191C1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPending
                              ? const Color(0xFF006E2F)
                              : const Color(0xFFECEEF0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isToday ? timeStr : DateFormat('dd/MM').format(appointment.scheduledAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isPending ? Colors.white : const Color(0xFF3D4A3D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Vehicle info (if available)
                  if (hasVehicle)
                    Text(
                      '${appointment.vehicleBrand ?? ''} ${appointment.vehicleModel ?? ''} • ${appointment.vehicleLicensePlate}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF3D4A3D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  // Service type
                  Text(
                    appointment.serviceTypeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6D7B6C),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    // Note
                    Row(
                      children: [
                        const Icon(
                          Icons.build_circle_outlined,
                          size: 14,
                          color: Color(0xFF6D7B6C),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6D7B6C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Chevron
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBCCBB9),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeableCard(AdminAppointment appointment) {
    return Dismissible(
      key: ValueKey(appointment.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(appointment),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFBA1A1A),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      child: _buildAppointmentCard(appointment),
    );
  }

  Future<bool> _confirmDelete(AdminAppointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa lịch hẹn'),
        content: Text('Bạn có chắc muốn xóa lịch hẹn của ${appointment.customerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    if (!mounted) return false;

    final result = await GetIt.instance<DeleteAppointment>()(appointment.id);

    return result.fold(
      (failure) {
        if (mounted) _showErrorSnackBar('Xóa thất bại: ${failure.message}');
        return false;
      },
      (_) {
        if (mounted) {
          context.read<AdminAppointmentBloc>().add(DeleteAppointmentEvent(id: appointment.id));
        }
        return true;
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ────────────────────────────────────────────────────────────────────
  // Bottom CTA
  // ────────────────────────────────────────────────────────────────────
  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF006E2F), Color(0xFF009844)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF006E2F).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _openNewIntake,
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              size: 22,
              color: Colors.white,
            ),
            label: const Text(
              'Tiếp nhận xe mới',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Actions
  // ────────────────────────────────────────────────────────────────────
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() => _isSearching = true);
    
    try {
      final dataSource = GetIt.instance<VehicleRemoteDataSource>();
      
      if (_searchTab == 0) {
        // Search by License Plate
        final vehicle = await dataSource.getVehicleByLicensePlate(query);
        if (vehicle != null && mounted) {
          AdminVehicleDetailSheet.show(context, vehicle, _openNewIntake);
        } else if (mounted) {
          _showErrorSnackBar('Không tìm thấy xe có biển số $query');
        }
      } else {
        // Search by Phone Number
        final customer = await dataSource.getCustomerByPhone(query);
        if (customer != null && mounted) {
          CustomerVehiclesSheet.show(context, customer, _openNewIntake);
        } else if (mounted) {
          _showErrorSnackBar('Không tìm thấy khách hàng với SĐT $query');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Đã xảy ra lỗi khi tìm kiếm');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _openQRScanner() async {
    final qrService = GetIt.instance<QRScannerService>();
    final scannedCode = await qrService.scanQRCode(context);
    
    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      _searchTab = 0;
      _searchController.text = scannedCode;
      await _performSearch();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFBA1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }


  void _openAppointmentDetails(AdminAppointment appointment) {
    final timeStr = DateFormat('HH:mm').format(appointment.scheduledAt);
    final dateStr = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(appointment.scheduledAt);
    final isToday = _isSameDay(appointment.scheduledAt, DateTime.now());

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBCCBB9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header: tên + trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        appointment.customerName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: appointment.isPending
                            ? const Color(0xFFFEF3C7)
                            : appointment.isConfirmed
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        appointment.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: appointment.isPending
                              ? const Color(0xFFD97706)
                              : appointment.isConfirmed
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                if (appointment.customerPhone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    appointment.customerPhone!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6D7B6C),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Thời gian
                _infoRow(Icons.calendar_today, isToday ? timeStr : '$dateStr • $timeStr'),
                const SizedBox(height: 12),

                // Dịch vụ
                _infoRow(Icons.build_outlined, appointment.serviceTypeLabel),
                const SizedBox(height: 12),

                // Xe
                if (appointment.vehicleLicensePlate != null) ...[
                  _infoRow(
                    Icons.directions_car,
                    '${appointment.vehicleBrand ?? ''} ${appointment.vehicleModel ?? ''} • ${appointment.vehicleLicensePlate}',
                  ),
                  const SizedBox(height: 12),
                ],

                // Ghi chú
                if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                  _infoRow(Icons.notes, appointment.notes!),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Nút: Tiếp nhận xe
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006E2F), Color(0xFF009844)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        final plate = appointment.vehicleLicensePlate;
                        _openNewIntake(plate ?? '', appointment.id);
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: const Text('Tiếp nhận xe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF006E2F)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF191C1E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _openNewIntake([String licensePlate = '', String? appointmentId]) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => VehicleIntakePage(
          initialLicensePlate: licensePlate.isNotEmpty ? licensePlate : null,
          appointmentId: appointmentId,
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
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────
/// Formatter tự động uppercase biển số
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

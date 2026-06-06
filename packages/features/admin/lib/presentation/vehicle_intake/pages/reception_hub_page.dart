import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';
import '../../../data/datasources/remote/vehicle_remote_datasource.dart';
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

class _ReceptionHubPageState extends State<ReceptionHubPage>
    with SingleTickerProviderStateMixin {
  int _searchTab = 0; // 0 = biển số, 1 = SĐT
  final _searchController = TextEditingController();
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  bool _isSearching = false;

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
    return FadeTransition(
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
  Widget _buildUpcomingSection() {
    // Mock data - sẽ được thay bằng API sau
    final upcomingCustomers = [
      const _UpcomingCustomer(
        name: 'Nguyễn Văn A',
        vehicleModel: 'VinFast Klara S',
        licensePlate: '29A-123.45',
        timeLabel: '14:30',
        timeType: _TimeType.scheduled,
        note: 'Bảo dưỡng định kỳ 5000km',
        hasAlert: false,
      ),
      const _UpcomingCustomer(
        name: 'Trần Thị B',
        vehicleModel: 'Dat Bike Weaver++',
        licensePlate: '59B-987.65',
        timeLabel: 'Đang chờ',
        timeType: _TimeType.waiting,
        note: 'Lỗi cell pin số 4',
        hasAlert: true,
      ),
    ];

    return Column(
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Khách hàng sắp đến',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF191C1E),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF006E2F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Customer cards
        ...upcomingCustomers.map(
          (customer) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCustomerCard(customer),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(_UpcomingCustomer customer) {
    final isWaiting = customer.timeType == _TimeType.waiting;

    return GestureDetector(
      onTap: () => _openVehicleDetails(customer),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: customer.hasAlert
                ? const Color(0xFFBA1A1A).withValues(alpha: 0.15)
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
            // Vehicle icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  Icons.electric_bike_rounded,
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
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      // Time badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isWaiting
                              ? const Color(0xFFECEEF0)
                              : const Color(0xFF006E2F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          customer.timeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isWaiting
                                ? const Color(0xFF3D4A3D)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Vehicle + plate
                  Text(
                    '${customer.vehicleModel} • ${customer.licensePlate}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3D4A3D),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Note
                  Row(
                    children: [
                      Icon(
                        customer.hasAlert
                            ? Icons.warning_amber_rounded
                            : Icons.build_circle_outlined,
                        size: 14,
                        color: customer.hasAlert
                            ? const Color(0xFFBA1A1A)
                            : const Color(0xFF6D7B6C),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          customer.note,
                          style: TextStyle(
                            fontSize: 12,
                            color: customer.hasAlert
                                ? const Color(0xFFBA1A1A)
                                : const Color(0xFF6D7B6C),
                            fontWeight: customer.hasAlert
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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


  void _openVehicleDetails(_UpcomingCustomer customer) {
    // TODO: navigate to vehicle detail page
  }

  void _openNewIntake([String licensePlate = '']) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => VehicleIntakePage(
          initialLicensePlate: licensePlate.isNotEmpty ? licensePlate : null,
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
// Helpers & Models
// ────────────────────────────────────────────────────────────────────
enum _TimeType { scheduled, waiting }

class _UpcomingCustomer {
  final String name;
  final String vehicleModel;
  final String licensePlate;
  final String timeLabel;
  final _TimeType timeType;
  final String note;
  final bool hasAlert;

  const _UpcomingCustomer({
    required this.name,
    required this.vehicleModel,
    required this.licensePlate,
    required this.timeLabel,
    required this.timeType,
    required this.note,
    required this.hasAlert,
  });
}

/// Formatter tự động uppercase biển số
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

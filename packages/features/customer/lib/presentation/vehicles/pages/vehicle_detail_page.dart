import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../domain/entities/customer_vehicle.dart';
import '../../../domain/entities/customer_work_order.dart';
import '../bloc/customer_work_order_bloc.dart';
import 'customer_work_order_detail_page.dart';
import '../widgets/customer_bottom_nav.dart';
import 'my_vehicles_page.dart';
import '../../account/pages/customer_account_page.dart';
import '../../warranties/pages/customer_warranty_page.dart';

class VehicleDetailPage extends StatefulWidget {
  final CustomerVehicle vehicle;

  const VehicleDetailPage({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  late final CustomerWorkOrderBloc _workOrderBloc;

  @override
  void initState() {
    super.initState();
    _workOrderBloc = GetIt.instance<CustomerWorkOrderBloc>();
    _workOrderBloc.add(LoadWorkOrdersForVehicle(widget.vehicle.id));
  }

  @override
  void dispose() {
    _workOrderBloc.close();
    super.dispose();
  }

  void _showQRDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Mã định danh xe',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutBack.transform(animation.value);
        return Transform.scale(
          scale: curvedValue,
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildBeautifulQRCard(dialogContext),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBeautifulQRCard(BuildContext dialogContext) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Close button at top right
          Positioned(
            right: -8,
            top: -8,
            child: GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Header Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFF006E2F),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mã định danh xe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Đưa mã này cho kỹ thuật viên quét khi nhận xe',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // QR Code with HUD Brackets
              SizedBox(
                width: 216,
                height: 216,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // QR Container with shadow
                    Container(
                      width: 204,
                      height: 204,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF006E2F).withValues(alpha: 0.08),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: widget.vehicle.qrData,
                        version: QrVersions.auto,
                        size: 180,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: Color(0xFF006E2F),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    // Corner HUD Guides
                    _buildQRScannerGuides(),
                    // Premium center vehicle brand icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFECFDF5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF006E2F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.electric_bike_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Vehicle Info
              Text(
                widget.vehicle.model,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              // Vietnam-style license plate pill
              _buildLicensePlatePill(context),
              const SizedBox(height: 28),
              // Close button with premium design
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF006E2F),
                        Color(0xFF009844),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF006E2F).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRScannerGuides() {
    const double cornerSize = 20.0;
    const double borderWidth = 3.0;
    const Color cornerColor = Color(0xFF006E2F);
    
    return Stack(
      children: [
        // Top Left
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: borderWidth),
                left: BorderSide(color: cornerColor, width: borderWidth),
              ),
            ),
          ),
        ),
        // Top Right
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: borderWidth),
                right: BorderSide(color: cornerColor, width: borderWidth),
              ),
            ),
          ),
        ),
        // Bottom Left
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: borderWidth),
                left: BorderSide(color: cornerColor, width: borderWidth),
              ),
            ),
          ),
        ),
        // Bottom Right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: borderWidth),
                right: BorderSide(color: cornerColor, width: borderWidth),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLicensePlatePill(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(
          ClipboardData(text: widget.vehicle.licensePlate),
        );
        _showBeautifulToast(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1E293B),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFBA1A1A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.vehicle.licensePlate.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.copy_all_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showBeautifulToast(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1.0 - value) * -20),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF006E2F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Đã sao chép biển số',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Đã copy ${widget.vehicle.licensePlate} vào bộ nhớ tạm',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _workOrderBloc,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildHeroSection(),
                      const SizedBox(height: 24),
                      _buildRepairHistorySection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              CustomerBottomNav(
                selectedIndex: 0,
                onItemSelected: (index) {
                  if (index == 0) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const MyVehiclesPage(),
                      ),
                      (route) => false,
                    );
                  } else if (index == 3) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const CustomerAccountPage(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          // Title
          Text(
            'Chi tiết xe',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          // Notification button
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image with warranty badge
            _buildHeroImage(),
            // Vehicle identity info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.vehicle.model,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                text: 'Biển số: ',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                                children: [
                                  TextSpan(
                                    text: widget.vehicle.licensePlate,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showQRDialog(context),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(
                            Icons.qr_code_2,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Quick info grid
                  _buildQuickInfoGrid(),
                  const SizedBox(height: 16),
                  // Warranty button
                  _buildWarrantyButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantyButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerWarrantyPage(
              vehicleId: widget.vehicle.id,
              licensePlate: widget.vehicle.licensePlate,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFECFDF5),
              Color(0xFFD1FAE5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF86EFAC),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF059669),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin bảo hành',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Xem chi tiết các loại bảo hành của xe',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF059669).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Color(0xFF059669),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    final imageUrl = widget.vehicle.imageUrl;
    final warrantyDays = widget.vehicle.warrantyDaysRemaining;
    final badgeText = warrantyDays != null
        ? 'Còn bảo hành: $warrantyDays ngày'
        : 'Hết bảo hành';

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: imageUrl == null
              ? Container(
                  color: AppColors.surfaceContainerHigh,
                  child: const Icon(
                    Icons.electric_bike,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(
                      Icons.electric_bike,
                      size: 64,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
        // Warranty badge overlay
        Positioned(
          top: 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.security,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  badgeText,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoGrid() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildInfoTile(
            icon: Icons.speed,
            iconBgColor: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            value: widget.vehicle.currentKm != null ? _formatNumber(widget.vehicle.currentKm!) : '---',
            label: 'KM ODO',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoTile(
            icon: Icons.palette,
            iconBgColor: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            value: widget.vehicle.color ?? '---',
            label: 'MÀU SẮC',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoTile(
            icon: Icons.calendar_month,
            iconBgColor: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFEA580C),
            value: widget.vehicle.manufactureYear != null ? '${widget.vehicle.manufactureYear}' : '---',
            label: 'NĂM SX',
          ),
        ),
      ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairHistorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lịch sử sửa chữa',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list,
                    size: 18, color: AppColors.onSurfaceVariant),
                label: Text(
                  'Lọc theo trạng thái',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Work orders list
          BlocBuilder<CustomerWorkOrderBloc, CustomerWorkOrderState>(
            builder: (context, state) {
              if (state is CustomerWorkOrderLoading ||
                  state is CustomerWorkOrderInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CustomerWorkOrderError) {
                return Center(
                  child: Text(
                    state.message,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error),
                  ),
                );
              }

              final orders =
                  state is CustomerWorkOrderLoaded ? state.workOrders : [];
              if (orders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Chưa có phiếu sửa chữa cho xe này',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _WorkOrderCard(
                    workOrder: order,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerWorkOrderDetailPage(
                          workOrder: order,
                          vehicle: widget.vehicle,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- Inline Work Order Card Widget ---
class _WorkOrderCard extends StatelessWidget {
  final CustomerWorkOrder workOrder;
  final VoidCallback onTap;

  const _WorkOrderCard({
    required this.workOrder,
    required this.onTap,
  });

  bool get _isCompleted =>
      workOrder.status.toLowerCase() == 'completed' ||
      workOrder.status.toLowerCase() == 'hoan_thanh' ||
      workOrder.status.toLowerCase() == 'done';

  Color get _statusBgColor =>
      _isCompleted ? AppColors.primary : AppColors.error;

  Color get _cardBorderColor => _isCompleted
      ? AppColors.outlineVariant.withValues(alpha: 0.3)
      : AppColors.error.withValues(alpha: 0.2);

  Color get _cardBgColor => _isCompleted
      ? AppColors.surfaceContainerLowest
      : AppColors.errorContainer.withValues(alpha: 0.12);

  Color get _tagColor =>
      _isCompleted ? AppColors.primary : AppColors.error;

  Color get _leftBorderColor =>
      _isCompleted ? AppColors.primaryContainer : AppColors.error;

  String get _statusLabel {
    final s = workOrder.status.toLowerCase();
    if (s == 'completed' || s == 'hoan_thanh' || s == 'done') {
      return 'Hoàn thành';
    }
    if (s == 'pending' || s == 'cho_xu_ly') return 'Chờ xử lý';
    if (s == 'in_progress' || s == 'dang_xu_ly') return 'Đang xử lý';
    return workOrder.status;
  }

  IconData get _statusIcon =>
      _isCompleted ? Icons.check_circle : Icons.pending;

  String get _servicesSummary {
    if (workOrder.services.isEmpty) return workOrder.notes ?? '';
    return workOrder.services
        .map((s) => s.description ?? s.serviceType)
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  String get _formattedDate {
    final d = workOrder.createdAt;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: tag + status chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tagColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '#${workOrder.orderNumber}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _tagColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusBgColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _statusBgColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon,
                          size: 14, color: AppColors.onPrimary),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Order title + date
            Text(
              _cardTitle,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formattedDate,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Services summary with left border
            if (_servicesSummary.isNotEmpty)
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: _leftBorderColor.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _servicesSummary,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 16),
            // CTA button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const SizedBox.shrink(),
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Xem chi tiết phiếu',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward,
                        size: 16, color: AppColors.onPrimary),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _statusBgColor,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: _statusBgColor.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _cardTitle {
    final summary = _servicesSummary.trim();
    if (summary.isNotEmpty) {
      final firstItem = summary.split(',').first.trim();
      if (firstItem.isNotEmpty) {
        return firstItem.length > 42 ? '${firstItem.substring(0, 42)}…' : firstItem;
      }
    }

    final p = workOrder.priority.toLowerCase();
    if (p == 'emergency' || p == 'dot_xuat') return 'Sửa chữa đột xuất';
    if (p == 'scheduled' || p == 'dinh_ky') return 'Bảo dưỡng định kỳ';
    if (p == 'normal') return 'Phiếu sửa chữa';
    return 'Phiếu sửa chữa';
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import '../../../domain/entities/vehicle_detail.dart';
import '../bloc/vehicle_detail_bloc.dart';
import '../bloc/vehicle_detail_event.dart';
import '../bloc/vehicle_detail_state.dart';

class VehicleResultPage extends StatefulWidget {
  final String initialMode;
  final String? initialPlate;

  const VehicleResultPage({
    super.key,
    this.initialMode = 'vehicle',
    this.initialPlate,
  });

  @override
  State<VehicleResultPage> createState() => _VehicleResultPageState();
}

class _VehicleResultPageState extends State<VehicleResultPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isSearchFocused = false;
  bool _hasAutoSearched = false;

  static const _kGreen = Color(0xFF006E2F);
  static const _kBg = Color(0xFFF8FAFB);

  bool get _isWarrantyMode => widget.initialMode == 'warranty';

  @override
  void initState() {
    super.initState();
    if (widget.initialPlate != null) {
      _searchController.text = widget.initialPlate!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasAutoSearched) {
          _hasAutoSearched = true;
          _doSearch(widget.initialPlate!);
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _doSearch(String plate) {
    _focusNode.unfocus();
    if (_isWarrantyMode) {
      context
          .read<VehicleDetailBloc>()
          .add(SearchVehicleWarranty(licensePlate: plate));
    } else {
      context
          .read<VehicleDetailBloc>()
          .add(SearchVehicleByPlate(licensePlate: plate));
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim().toUpperCase();
    if (query.isEmpty) return;
    _doSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF191C1E)),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.initialMode == 'warranty'
                    ? Icons.shield_outlined
                    : Icons.two_wheeler_rounded,
                size: 18,
                color: _kGreen,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.initialMode == 'warranty' ? 'Tra bảo hành' : 'Tra biển số',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF191C1E),
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSearchFocused ? _kGreen : const Color(0xFFE5E7EB),
          width: _isSearchFocused ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSearchFocused
                ? _kGreen.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: _isSearchFocused ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search_rounded,
            color: _isSearchFocused ? _kGreen : const Color(0xFF9CA3AF),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode..addListener(() {
                setState(() => _isSearchFocused = _focusNode.hasFocus);
              }),
              keyboardType: TextInputType.text,
              inputFormatters: [_UpperCaseFormatter()],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191C1E),
                letterSpacing: 0.3,
              ),
              decoration: const InputDecoration(
                hintText: 'Nhập biển số xe',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                context
                    .read<VehicleDetailBloc>()
                    .add(const ClearVehicleResult());
              },
              icon: const Icon(Icons.close_rounded,
                  color: Color(0xFF6D7B6C), size: 20),
            ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: GestureDetector(
              onTap: _onSearch,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isSearchFocused
                        ? [const Color(0xFF006E2F), const Color(0xFF16A34A)]
                        : [const Color(0xFF006E2F), const Color(0xFF22C55E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _kGreen.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<VehicleDetailBloc, VehicleDetailState>(
      builder: (context, state) {
        if (state is VehicleDetailInitial) {
          return _buildInitialHint();
        }
        if (state is VehicleDetailLoading) {
          return _buildLoading();
        }
        if (state is VehicleDetailNotFound) {
          return _buildNotFound(state.message);
        }
        if (state is VehicleDetailError) {
          return _buildError(state.message);
        }
        if (state is VehicleDetailLoaded) {
          return _buildResult(state.vehicle);
        }
        if (state is VehicleWarrantyLoaded) {
          return _buildWarrantyResult(state.vehicle, state.warranty);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInitialHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.two_wheeler_rounded,
              size: 46,
              color: Color(0xFF006E2F),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tra cứu xe',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập biển số xe để xem thông tin\nvà lịch sử sửa chữa.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_kGreen),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Đang tìm kiếm...',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Không tìm thấy xe',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kiểm tra lại biển số xe.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Lỗi tải dữ liệu',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResult(VehicleDetail vehicle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVehicleInfoCard(vehicle),
          const SizedBox(height: 16),
          _buildOwnerCard(vehicle),
          const SizedBox(height: 24),
          _buildWorkOrdersSection(vehicle.recentWorkOrders),
        ],
      ),
    );
  }

  Widget _buildWarrantyResult(VehicleDetail vehicle, WarrantyResponse warranty) {
    final hasWarranties = warranty.warranties.isNotEmpty;
    final hasPartWarranties = warranty.partWarranties.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVehicleInfoCard(vehicle),
          const SizedBox(height: 16),
          _buildOwnerCard(vehicle),
          const SizedBox(height: 24),
          _buildWarrantySection(warranty),
          if (hasWarranties || hasPartWarranties) const SizedBox(height: 16),
          if (hasWarranties) _buildWarrantyCardList(warranty.warranties),
          if (hasPartWarranties) ...[
            const SizedBox(height: 16),
            _buildPartWarrantyList(warranty.partWarranties),
          ],
          const SizedBox(height: 24),
          _buildWorkOrdersSection(vehicle.recentWorkOrders),
        ],
      ),
    );
  }

  Widget _buildWarrantySection(WarrantyResponse warranty) {
    final vehicleW = warranty.vehicle;
    final hasWarranties = warranty.warranties.isNotEmpty;
    final hasPartWarranties = warranty.partWarranties.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058BE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin bảo hành',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasWarranties && !hasPartWarranties)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 40, color: const Color(0xFF9CA3AF).withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    const Text(
                      'Chưa có thông tin bảo hành',
                      style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'Xe: ${vehicleW.brand ?? ''} ${vehicleW.model} - ${vehicleW.licensePlate}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${hasWarranties} bảo hành xe · $hasPartWarranties bảo hành phụ tùng',
                style: const TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF0058BE),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantyCardList(List<WarrantyModel> warranties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Bảo hành xe (${warranties.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191C1E),
            ),
          ),
        ),
        ...warranties.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildWarrantyCard(w),
            )),
      ],
    );
  }

  Widget _buildPartWarrantyList(List<PartWarrantyModel> partWarranties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Bảo hành phụ tùng (${partWarranties.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191C1E),
            ),
          ),
        ),
        ...partWarranties.map((pw) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPartWarrantyCard(pw),
            )),
      ],
    );
  }

  Widget _buildWarrantyCard(WarrantyModel w) {
    final daysLeft = w.daysRemaining;
    final isExpired = daysLeft <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : daysLeft <= 30
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                  : const Color(0xFF22C55E).withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isExpired
                    ? const Color(0xFFFEE2E2)
                    : daysLeft <= 30
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _warrantyIcon(w.warrantyType),
                size: 20,
                color: isExpired
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF0058BE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _warrantyTypeLabel(w.warrantyType),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${w.startDate.day}/${w.startDate.month}/${w.startDate.year}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 10, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        '${w.expiryDate.day}/${w.expiryDate.month}/${w.expiryDate.year}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isExpired
                    ? const Color(0xFFFEE2E2)
                    : daysLeft <= 30
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isExpired ? 'Hết hạn' : 'Còn $daysLeft ngày',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isExpired
                      ? const Color(0xFFEF4444)
                      : daysLeft <= 30
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartWarrantyCard(PartWarrantyModel pw) {
    final daysLeft = pw.daysRemaining;
    final isExpired = daysLeft <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : daysLeft <= 30
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                  : const Color(0xFF22C55E).withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.precision_manufacturing_outlined,
                  size: 20, color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pw.partName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pw.startDate.day}/${pw.startDate.month}/${pw.startDate.year} - ${pw.expiryDate.day}/${pw.expiryDate.month}/${pw.expiryDate.year}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isExpired
                    ? const Color(0xFFFEE2E2)
                    : daysLeft <= 30
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isExpired ? 'Hết hạn' : 'Còn $daysLeft ngày',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isExpired
                      ? const Color(0xFFEF4444)
                      : daysLeft <= 30
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _warrantyIcon(String type) {
    switch (type.toUpperCase()) {
      case 'BATTERY':
        return Icons.battery_charging_full;
      case 'MOTOR':
        return Icons.electrical_services;
      case 'FRAME':
        return Icons.build_outlined;
      default:
        return Icons.verified_outlined;
    }
  }

  String _warrantyTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'BATTERY':
        return 'Bảo hành pin';
      case 'MOTOR':
        return 'Bảo hành motor';
      case 'FRAME':
        return 'Bảo hành khung xe';
      default:
        return type;
    }
  }

  Widget _buildVehicleInfoCard(VehicleDetail vehicle) {
    final backgroundColor = vehicle.isUnderWarranty
        ? const Color(0xFFF0FDF4)
        : Colors.white;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: vehicle.isUnderWarranty
              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _kGreen.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              vehicle.licensePlate,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _kGreen,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          if (vehicle.isUnderWarranty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified,
                                      size: 12, color: Color(0xFF16A34A)),
                                  SizedBox(width: 4),
                                  Text(
                                    'BH',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        vehicle.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          if (vehicle.color != null)
                            _buildAttribute(Icons.palette_outlined,
                                vehicle.color!),
                          if (vehicle.manufactureYear != null)
                            _buildAttribute(Icons.calendar_today_outlined,
                                '${vehicle.manufactureYear}'),
                          if (vehicle.currentKm != null)
                            _buildAttribute(Icons.speed_outlined,
                                '${vehicle.currentKm} km'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttribute(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerCard(VehicleDetail vehicle) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _kGreen.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: _kGreen, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.ownerName ?? 'Chủ xe',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  if (vehicle.ownerPhone != null)
                    Text(
                      vehicle.ownerPhone!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ),
            if (vehicle.ownerPhone != null)
              Container(
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _callPhone(vehicle.ownerPhone!),
                  icon: const Icon(Icons.phone_rounded,
                      color: _kGreen, size: 22),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkOrdersSection(List<WorkOrderSummary> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Lịch sử sửa chữa',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF191C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (orders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: const Center(
              child: Text(
                'Chưa có lịch sử sửa chữa',
                style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
            ),
          )
        else
          ...orders.map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildWorkOrderCard(order),
              )),
      ],
    );
  }

  Widget _buildWorkOrderCard(WorkOrderSummary order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: _getStatusColor(order.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber ?? 'WO-${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (order.description != null)
                    Text(
                      order.description!.length > 60
                          ? '${order.description!.substring(0, 60)}...'
                          : order.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(order.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toUpperCase()) {
      case 'PENDING':
        color = const Color(0xFF9CA3AF);
        label = 'Chờ XL';
      case 'IN_PROGRESS':
        color = const Color(0xFF006E2F);
        label = 'Đang làm';
      case 'INSPECTION':
        color = const Color(0xFFF59E0B);
        label = 'Kiểm tra';
      case 'COMPLETED':
        color = const Color(0xFF3B82F6);
        label = 'Xong';
      case 'PAID':
        color = const Color(0xFF22C55E);
        label = 'Đã TT';
      case 'CANCELLED':
        color = const Color(0xFFEF4444);
        label = 'Hủy';
      default:
        color = const Color(0xFF9CA3AF);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFF9CA3AF);
      case 'IN_PROGRESS':
        return const Color(0xFF006E2F);
      case 'INSPECTION':
        return const Color(0xFFF59E0B);
      case 'COMPLETED':
        return const Color(0xFF3B82F6);
      case 'PAID':
        return const Color(0xFF22C55E);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  void _callPhone(String phone) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gọi: $phone'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../domain/entities/lookup_result.dart';
import '../../../presentation/vehicle_intake/widgets/admin_vehicle_detail_sheet.dart';
import '../../../presentation/vehicle_intake/pages/vehicle_intake_page.dart';
import '../bloc/lookup_bloc.dart';
import '../bloc/lookup_event.dart';
import '../bloc/lookup_state.dart';
import '../widgets/vehicle_search_result_card.dart';

/// Trang tra cứu xe — tìm kiếm theo biển số, tên xe hoặc quét QR
class VehicleLookupPage extends StatefulWidget {
  const VehicleLookupPage({super.key});

  @override
  State<VehicleLookupPage> createState() => _VehicleLookupPageState();
}

class _VehicleLookupPageState extends State<VehicleLookupPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  static const _kDebounceMs = 400;
  static const _kGreen = Color(0xFF006E2F);
  static const _kBg = Color(0xFFF7F9FB);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    // Auto focus search field and load recent vehicles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      context.read<LookupBloc>().add(
            const PerformLookupSearch(categoryId: 'vehicle', query: null),
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _kDebounceMs), () {
      if (!mounted) return;
      context.read<LookupBloc>().add(
            PerformLookupSearch(
              categoryId: 'vehicle',
              query: value.trim().isEmpty ? null : value.trim(),
            ),
          );
    });
  }

  void _onSearchSubmit() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    context.read<LookupBloc>().add(
          PerformLookupSearch(
            categoryId: 'vehicle',
            query: query.isEmpty ? null : query,
          ),
        );
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.requestFocus();
    _debounce?.cancel();
    context.read<LookupBloc>().add(
          const PerformLookupSearch(categoryId: 'vehicle', query: null),
        );
  }

  void _openVehicleDetail(VehicleLookupResult vehicle) {
    // Chuyển đổi VehicleLookupResult → VehicleModel để dùng AdminVehicleDetailSheet
    final model = VehicleModel(
      id: vehicle.id,
      licensePlate: vehicle.licensePlate,
      brand: vehicle.brand,
      model: vehicle.model,
      color: vehicle.color,
      imageUrl: vehicle.imageUrl,
      manufactureYear: vehicle.manufactureYear,
      currentKm: vehicle.currentKm,
      warrantyExpiry: vehicle.warrantyExpiry,
      ownerId: vehicle.ownerId,
      ownerName: vehicle.ownerName,
      ownerPhone: vehicle.ownerPhone,
      createdAt: vehicle.createdAt,
    );

    AdminVehicleDetailSheet.show(
      context,
      model,
      (licensePlate) => _openIntake(licensePlate),
    );
  }

  void _openIntake(String licensePlate) {
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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF191C1E)),
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.two_wheeler_rounded, size: 20, color: _kGreen),
              SizedBox(width: 8),
              Text(
                'Tra cứu xe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kGreen,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: const Color(0xFFDAE4DC).withValues(alpha: 0.5),
            ),
          ),
        ),
        body: Column(
          children: [
            // ── Search Bar ──────────────────────────────────────────────
            _buildSearchBar(),
            // ── Results ─────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<LookupBloc, LookupState>(
                builder: (context, state) {
                  if (state is LookupInitial || state is LookupCategoriesLoaded) {
                    return _buildInitialHint();
                  }
                  if (state is LookupSearchLoading) {
                    return _buildLoading();
                  }
                  if (state is LookupSearchError) {
                    return _buildError(state.message);
                  }
                  if (state is LookupSearchLoaded) {
                    if (state.selectedCategoryId != 'vehicle') {
                      return _buildInitialHint();
                    }
                    if (state.results.isEmpty) {
                      return _buildEmpty();
                    }
                    return _buildResultList(state.results, state.query);
                  }
                  return _buildInitialHint();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBCCBB9), width: 1.5),
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
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF6D7B6C),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              keyboardType: TextInputType.text,
              inputFormatters: [_UpperCaseFormatter()],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191C1E),
                letterSpacing: 0.5,
              ),
              decoration: const InputDecoration(
                hintText: 'Biển số, model, hãng xe...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _onSearchSubmit(),
            ),
          ),
          // Clear / Search button
          ValueListenableBuilder(
            valueListenable: _searchController,
            builder: (_, value, __) {
              if (value.text.isNotEmpty) {
                return IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF6D7B6C),
                    size: 20,
                  ),
                );
              }
              return const SizedBox(width: 8);
            },
          ),
          GestureDetector(
            onTap: _onSearchSubmit,
            child: Container(
              margin: const EdgeInsets.all(6),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _kGreen.withValues(alpha: 0.3),
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
        ],
      ),
    );
  }

  Widget _buildInitialHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.two_wheeler_rounded,
              size: 42,
              color: Color(0xFF455A64),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tìm kiếm xe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập biển số, tên model hoặc hãng xe\nđể tìm thông tin xe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6D7B6C),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_kGreen),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: const Color(0xFF455A64).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy xe nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thử từ khóa khác hoặc kiểm tra lại biển số.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6D7B6C)),
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
          const Icon(Icons.error_outline_rounded,
              size: 48, color: Color(0xFFBA1A1A)),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải dữ liệu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6D7B6C)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _onSearchSubmit,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kGreen,
              side: const BorderSide(color: _kGreen),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList(List<LookupResult> results, String? query) {
    final vehicles = results.whereType<VehicleLookupResult>().toList();
    
    final isDefaultList = query == null || query.trim().isEmpty;
    final headerText = isDefaultList 
        ? 'Xe mới cập nhật gần đây' 
        : '${vehicles.length} kết quả tìm kiếm cho "$query"';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            headerText,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6D7B6C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return VehicleSearchResultCard(
                vehicle: vehicles[index],
                onTap: () => _openVehicleDetail(vehicles[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

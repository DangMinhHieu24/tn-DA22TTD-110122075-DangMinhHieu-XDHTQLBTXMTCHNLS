import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/entities/vehicle_detail.dart';
import '../bloc/vehicle_list_bloc.dart';
import '../bloc/vehicle_list_event.dart';
import '../bloc/vehicle_list_state.dart';
import '../bloc/vehicle_detail_bloc.dart';
import 'vehicle_result_page.dart';

class VehicleListPage extends StatefulWidget {
  const VehicleListPage({super.key});

  @override
  State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isSearchFocused = false;
  bool _initialLoaded = false;

  static const _kGreen = Color(0xFF006E2F);
  static const _kBg = Color(0xFFF8FAFB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialLoaded) {
        _initialLoaded = true;
        context.read<VehicleListBloc>().add(const LoadVehicles());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context
          .read<VehicleListBloc>()
          .add(SearchVehicles(query: value.trim()));
    });
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.two_wheeler_rounded, size: 18, color: _kGreen),
            SizedBox(width: 10),
            Text(
              'Danh sách xe',
              style: TextStyle(
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191C1E),
              ),
              decoration: const InputDecoration(
                hintText: 'Biển số, hãng, model...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _searchController,
            builder: (_, value, __) {
              if (value.text.isNotEmpty) {
                return IconButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<VehicleListBloc>().add(const LoadVehicles());
                  },
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF6D7B6C), size: 20),
                );
              }
              return const SizedBox(width: 8);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<VehicleListBloc, VehicleListState>(
      builder: (context, state) {
        if (state is VehicleListInitial || state is VehicleListLoading) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_kGreen),
            ),
          );
        }
        if (state is VehicleListError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Color(0xFFDC2626)),
                const SizedBox(height: 16),
                Text(state.message,
                    style: const TextStyle(color: Color(0xFF6B7280))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<VehicleListBloc>().add(const LoadVehicles()),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        if (state is VehicleListLoaded) {
          final vehicles = state.vehicles;
          if (vehicles.isEmpty) {
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
                    child: const Icon(Icons.two_wheeler_rounded,
                        size: 40, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Không có xe nào',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<VehicleListBloc>().add(const LoadVehicles());
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: vehicles.length,
              itemBuilder: (context, index) =>
                  _buildVehicleCard(vehicles[index]),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildVehicleCard(VehicleDetail vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: vehicle.isUnderWarranty
              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openVehicleDetail(vehicle),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: vehicle.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          vehicle.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.two_wheeler_rounded,
                              color: Color(0xFF9CA3AF),
                              size: 24),
                        ),
                      )
                    : const Icon(Icons.two_wheeler_rounded,
                        color: Color(0xFF9CA3AF), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          vehicle.licensePlate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _kGreen,
                            letterSpacing: 1,
                          ),
                        ),
                        if (vehicle.isUnderWarranty) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              size: 14, color: Color(0xFF16A34A)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.ownerName ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _openVehicleDetail(VehicleDetail vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: GetIt.instance<VehicleDetailBloc>(),
          child: VehicleResultPage(
            initialMode: 'warranty',
            initialPlate: vehicle.licensePlate,
          ),
        ),
      ),
    );
  }
}

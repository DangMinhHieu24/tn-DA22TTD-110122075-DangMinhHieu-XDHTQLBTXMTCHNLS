import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:get_it/get_it.dart';
import 'package:design_system/design_system.dart';

class CustomerWarrantyPage extends StatefulWidget {
  final String vehicleId;
  final String? licensePlate;

  const CustomerWarrantyPage({
    super.key,
    required this.vehicleId,
    this.licensePlate,
  });

  @override
  State<CustomerWarrantyPage> createState() => _CustomerWarrantyPageState();
}

class _CustomerWarrantyPageState extends State<CustomerWarrantyPage> {
  late final WarrantyService _warrantyService;
  bool _isLoading = true;
  String? _errorMessage;
  WarrantyResponse? _warrantyResponse;

  @override
  void initState() {
    super.initState();
    _warrantyService = GetIt.instance<WarrantyService>();
    _loadWarranties();
  }

  Future<void> _loadWarranties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _warrantyService.getVehicleWarranties(widget.vehicleId);
      if (mounted) {
        setState(() {
          _warrantyResponse = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin bảo hành',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.licensePlate != null)
              Text(
                widget.licensePlate!,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF15803D)),
            onPressed: _loadWarranties,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF15803D),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_warrantyResponse == null) {
      return _buildErrorState(message: 'Không có dữ liệu');
    }

    return RefreshIndicator(
      onRefresh: _loadWarranties,
      color: const Color(0xFF15803D),
      child: WarrantyInfoWidget(
        warrantyResponse: _warrantyResponse!,
        showEditActions: false, // Customer không được sửa
        showVehicleInfo: true,
      ),
    );
  }

  Widget _buildErrorState({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              message ?? _errorMessage ?? 'Đã có lỗi xảy ra',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadWarranties,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

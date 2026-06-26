import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'dart:ui' as ui;

String _serviceLabel(String? type) => switch (type) {
  'MAINTENANCE' => 'Bảo dưỡng định kỳ',
  'BATTERY_CHECK' => 'Kiểm tra pin/sạc',
  'BRAKES_TIRES' => 'Phanh & Lốp',
  'OTHER_REPAIR' => 'Sửa chữa khác',
  _ => type ?? '',
};

class WorkOrderDetailPage extends StatefulWidget {
  final String workOrderId;
  const WorkOrderDetailPage({super.key, required this.workOrderId});

  @override
  State<WorkOrderDetailPage> createState() => _WorkOrderDetailPageState();
}

class _WorkOrderDetailPageState extends State<WorkOrderDetailPage> {
  Map<String, dynamic>? _workOrder;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;
  final _pointsCtrl = TextEditingController();
  bool _redeeming = false;
  List<dynamic> _manualWarranties = [];
  List<dynamic> _partWarranties = [];
  int _selectedPhotoTab = 0;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = GetIt.instance<Dio>();
      final res = await dio.get('/work-orders/${widget.workOrderId}');
      final wo = res.data['data'] as Map<String, dynamic>;

      List<dynamic> manualWarranties = [];
      List<dynamic> partWarranties = [];

      final vehicleId = wo['vehicle']?['id'] as String?;
      if (vehicleId != null) {
        try {
          final wRes = await dio.get('/warranties/vehicles/$vehicleId/warranties');
          if (wRes.data['success'] == true) {
            manualWarranties = wRes.data['data']['warranties'] as List<dynamic>? ?? [];
            partWarranties = wRes.data['data']['partWarranties'] as List<dynamic>? ?? [];
          }
        } catch (e) {
          debugPrint('Error fetching vehicle warranties: $e');
        }
      }

      setState(() {
        _workOrder = wo;
        _manualWarranties = manualWarranties;
        _partWarranties = partWarranties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  bool _isServiceCovered(Map<String, dynamic> service) {
    final serviceType = (service['serviceType'] as String?)?.toUpperCase() ?? '';
    final price = (service['price'] as num?)?.toDouble() ?? 0;
    if (price <= 0) return false;

    for (final w in _manualWarranties) {
      final wStatus = w['status'] as String?;
      if (wStatus != 'ACTIVE' && wStatus != 'EXPIRING_SOON') continue;

      final wType = (w['warrantyType'] as String?)?.toUpperCase() ?? '';

      if (wType == 'VEHICLE' || wType == 'GENERAL' || wType == 'ALL') {
        return true;
      }

      if (serviceType == 'BATTERY_CHECK' && (wType == 'BATTERY' || wType == 'PIN' || wType == 'CHARGER')) {
        return true;
      }
      if (serviceType == 'BRAKES_TIRES' && (wType == 'BRAKE' || wType == 'TIRE' || wType == 'PHANH' || wType == 'LOP')) {
        return true;
      }
      if (serviceType == 'MAINTENANCE' && (wType == 'MAINTENANCE' || wType == 'BAO_DUONG')) {
        return true;
      }
    }
    return false;
  }

  bool _isPartCovered(Map<String, dynamic> partUsed) {
    final partName = (partUsed['part']?['partName'] as String?)?.toLowerCase() ?? '';
    final unitPrice = (partUsed['unitPrice'] as num?)?.toDouble() ?? 0;
    if (unitPrice <= 0) return false;

    for (final w in _manualWarranties) {
      final wStatus = w['status'] as String?;
      if (wStatus != 'ACTIVE' && wStatus != 'EXPIRING_SOON') continue;

      final wType = (w['warrantyType'] as String?)?.toUpperCase() ?? '';
      if (wType == 'VEHICLE' || wType == 'GENERAL' || wType == 'ALL') {
        return true;
      }

      if (partName.contains('pin') || partName.contains('battery') || partName.contains('sạc') || partName.contains('charger')) {
        if (wType == 'BATTERY' || wType == 'PIN' || wType == 'CHARGER') {
          return true;
        }
      }
    }

    for (final pw in _partWarranties) {
      final pwStatus = pw['status'] as String?;
      if (pwStatus != 'ACTIVE' && pwStatus != 'EXPIRING_SOON') continue;

      final pwPartName = (pw['partName'] as String?)?.toLowerCase() ?? '';
      if (partName == pwPartName ||
          (partName.contains(pwPartName) && pwPartName.length > 3) ||
          (pwPartName.contains(partName) && partName.length > 3)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _applyWarrantyPrice(String itemType, String itemId) async {
    setState(() => _isUpdating = true);
    try {
      final dio = GetIt.instance<Dio>();
      final res = await dio.patch(
        '/work-orders/${widget.workOrderId}/items/price',
        data: {
          'itemType': itemType,
          'itemId': itemId,
          'price': 0,
        },
      );

      if (res.data['success'] == true) {
        await _fetchDetail();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Đã áp dụng bảo hành miễn phí (0đ) thành công!'),
          backgroundColor: const Color(0xFF006E2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi áp dụng bảo hành: $e'),
        backgroundColor: const Color(0xFFBA1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      final dio = GetIt.instance<Dio>();
      await dio.patch(
        '/work-orders/${widget.workOrderId}/status',
        data: {'status': newStatus},
      );
      await _fetchDetail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã cập nhật trạng thái: ${_statusLabel(newStatus)}'),
        backgroundColor: const Color(0xFF006E2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.of(context).pop(true); // return true to refresh list
    } catch (e) {
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi: $e'),
        backgroundColor: const Color(0xFFBA1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  Future<void> _redeemPoints() async {
    final text = _pointsCtrl.text.trim();
    final points = int.tryParse(text);
    if (points == null || points <= 0) return;
    setState(() => _redeeming = true);
    try {
      final dio = GetIt.instance<Dio>();
      await dio.post('/work-orders/${widget.workOrderId}/redeem-points', data: {'points': points});
      _pointsCtrl.clear();
      await _fetchDetail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã áp dụng điểm thưởng thành công'),
        backgroundColor: Color(0xFF006E2F),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi: $e'),
        backgroundColor: const Color(0xFFBA1A1A),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  void _showPrintPreview() {
    if (_workOrder == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrintPreviewSheet(workOrder: _workOrder!),
    );
  }

  void _showConfirmDialog(String status) {
    final label = _statusLabel(status);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_statusIcon(status), color: _statusColor(status)),
            const SizedBox(width: 8),
            const Text('Xác nhận', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text('Bạn có chắc muốn chuyển trạng thái sang "$label" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(status);
            },
            style: FilledButton.styleFrom(backgroundColor: _statusColor(status)),
            child: Text('Xác nhận $label'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF006E2F)))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFBA1A1A)),
          const SizedBox(height: 12),
          Text('Lỗi: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _fetchDetail, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final wo = _workOrder!;
    final status = (wo['status'] ?? 'PENDING') as String;

    return Column(
      children: [
        _buildHeader(wo, status),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVehicleCard(wo),
                const SizedBox(height: 16),
                _buildWarrantyRecommendations(wo),
                _buildServicesCard(wo),
                const SizedBox(height: 16),
                _buildPartsCard(wo),
                const SizedBox(height: 16),
                _buildTechnicianCard(wo),
                if ((wo['photos'] as List?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  _buildPhotosCard(wo),
                ],
                const SizedBox(height: 16),
                _buildTotalCard(wo),
                const SizedBox(height: 16),
                _buildLoyaltyCard(wo),
                if (wo['notes'] != null && wo['notes'].toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(wo),
                ],
                const SizedBox(height: 20),
                _buildActionButtons(status),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarrantyRecommendations(Map<String, dynamic> wo) {
    final services = (wo['services'] as List<dynamic>? ?? []);
    final parts = (wo['partsUsed'] as List<dynamic>? ?? []);

    final matchedServices = services.where((s) => _isServiceCovered(s)).toList();
    final matchedParts = parts.where((p) => _isPartCovered(p)).toList();

    if (matchedServices.isEmpty && matchedParts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0F172A), // Deep Slate
                Color(0xFF064E3B), // Deep Emerald/Forest green (Xanh EV theme)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                blurRadius: 32,
                spreadRadius: -2,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: const Color(0xFF064E3B).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_rounded, 
                      size: 18, 
                      color: Color(0xFF34D399) // solid green shield
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khuyến Nghị Bảo Hành',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Phát hiện linh kiện/dịch vụ còn hạn bảo hành',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFA7F3D0), // Soft mint green
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: Colors.white12, height: 1, thickness: 1),
              ),
              
              ...matchedServices.map((s) {
                final typeLabel = _serviceLabel(s['serviceType'] as String?);
                final currentPrice = (s['price'] as num?)?.toDouble() ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded, 
                          size: 16, 
                          color: Color(0xFF34D399)
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              typeLabel,
                              style: const TextStyle(
                                fontSize: 13, 
                                fontWeight: FontWeight.w700, 
                                color: Colors.white
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Giá hiện tại: ${_formatCurrency(currentPrice)}',
                              style: const TextStyle(
                                fontSize: 11, 
                                color: Color(0xFF94A3B8)
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : () => _applyWarrantyPrice('SERVICE', s['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text(
                            'Áp dụng 0đ', 
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              
              ...matchedParts.map((p) {
                final partName = p['part']?['partName'] ?? 'Phụ tùng';
                final qty = p['quantity'] as num? ?? 1;
                final currentUnitPrice = (p['unitPrice'] as num?)?.toDouble() ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.memory_rounded, 
                          size: 16, 
                          color: Color(0xFF34D399)
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$partName (x$qty)',
                              style: const TextStyle(
                                fontSize: 13, 
                                fontWeight: FontWeight.w700, 
                                color: Colors.white
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Giá hiện tại: ${_formatCurrency(currentUnitPrice * qty)}',
                              style: const TextStyle(
                                fontSize: 11, 
                                color: Color(0xFF94A3B8)
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : () => _applyWarrantyPrice('PART', p['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text(
                            'Áp dụng 0đ', 
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> wo, String status) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF334155)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wo['orderNumber'] ?? '',
                  style: const TextStyle(
                    fontSize: 17, 
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A), 
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Phiếu Sửa Chữa',
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _StatusBadge(status: status),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _fetchDetail,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> wo) {
    final vehicle = wo['vehicle'] as Map<String, dynamic>? ?? {};
    final owner = vehicle['owner'] as Map<String, dynamic>? ?? {};
    final licensePlate = vehicle['licensePlate'] as String? ?? 'N/A';
    final model = vehicle['vehicleModel'] ?? vehicle['model'] ?? 'N/A';
    final chassis = vehicle['chassisNumber'] ?? 'N/A';
    final ownerName = owner['name'] as String? ?? 'N/A';
    final ownerPhone = owner['phoneNumber'] as String? ?? 'N/A';
    final ownerEmail = owner['email'] as String?;

    // Helper to get initials
    String getInitials(String name) {
      if (name.isEmpty || name == 'N/A') return 'KH';
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }

    return _Card(
      title: 'Thông Tin Xe & Khách',
      icon: Icons.two_wheeler_rounded,
      iconColor: const Color(0xFF10B981),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real-looking license plate container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 2, width: 32, color: const Color(0xFFBA1A1A)),
                    const SizedBox(height: 4),
                    Text(
                      licensePlate,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Số khung: ',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        Text(
                          chassis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Container(height: 1, color: const Color(0xFFF1F5F9)),
          ),
          
          // Customer Profile Info
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    getInitials(ownerName),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ownerPhone,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (ownerEmail != null && ownerEmail.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        ownerEmail,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard(Map<String, dynamic> wo) {
    final services = (wo['services'] as List<dynamic>? ?? []);
    return _Card(
      title: 'Dịch Vụ Thực Hiện',
      icon: Icons.build_circle_rounded,
      iconColor: const Color(0xFF3B82F6),
      child: services.isEmpty
          ? const Text('Chưa có dịch vụ', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13))
          : Column(
              children: services.asMap().entries.map((e) {
                final s = e.value as Map<String, dynamic>;
                final isDone = s['isDone'] == true;
                final type = s['serviceType'] as String?;
                
                final serviceIcon = switch (type) {
                  'MAINTENANCE' => Icons.construction_rounded,
                  'BATTERY_CHECK' => Icons.battery_charging_full_rounded,
                  'BRAKES_TIRES' => Icons.tire_repair_rounded,
                  _ => Icons.build_rounded,
                };
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDone ? const Color(0xFF15803D) : const Color(0xFF0F172A))
                            .withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                              : const Color(0xFF64748B).withValues(alpha: 0.08),
                        ),
                        child: Icon(
                          serviceIcon,
                          size: 16,
                          color: isDone ? const Color(0xFF15803D) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _serviceLabel(type),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDone
                                    ? const Color(0xFF14532D)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            if (s['description'] != null && s['description'].toString().trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  s['description'],
                                  style: TextStyle(
                                    fontSize: 11, 
                                    color: isDone 
                                        ? const Color(0xFF15803D).withValues(alpha: 0.8) 
                                        : const Color(0xFF64748B)
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (s['price'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDone 
                                ? const Color(0xFFDCFCE7).withValues(alpha: 0.5) 
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            s['price'] == 0 ? 'Miễn phí' : _formatCurrency(s['price']),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: isDone 
                                  ? const Color(0xFF15803D) 
                                  : (s['price'] == 0 ? const Color(0xFF10B981) : const Color(0xFF334155)),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPartsCard(Map<String, dynamic> wo) {
    final parts = (wo['partsUsed'] as List<dynamic>? ?? []);
    if (parts.isEmpty) return const SizedBox.shrink();
    return _Card(
      title: 'Phụ Tùng Sử Dụng',
      icon: Icons.inventory_2_rounded,
      iconColor: const Color(0xFFF59E0B),
      child: Column(
        children: [
          ...parts.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value as Map<String, dynamic>;
            final partInfo = p['part'] as Map<String, dynamic>? ?? {};
            final qty = p['quantity'] as num? ?? 0;
            final unitPrice = p['unitPrice'] as num? ?? 0;
            final total = qty * unitPrice;
            
            final partImgUrl = _resolveImageUrl(partInfo['imageUrl'] as String?);
            
            return Container(
              margin: EdgeInsets.only(bottom: idx == parts.length - 1 ? 0 : 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEF3C7), width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: partImgUrl.isNotEmpty
                          ? Image.network(
                              partImgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(
                                  Icons.settings_input_component_rounded,
                                  size: 20,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.settings_input_component_rounded,
                                size: 20,
                                color: Color(0xFFD97706),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partInfo['partName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 13.5, 
                            fontWeight: FontWeight.w800, 
                            color: Color(0xFF1E293B)
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đơn giá: ${_formatCurrency(unitPrice)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        if (total == 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_rounded, size: 10, color: Color(0xFF059669)),
                                SizedBox(width: 3),
                                Text(
                                  'Được bảo hành',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        total == 0 ? 'Bảo hành' : _formatCurrency(total),
                        style: TextStyle(
                          fontSize: 13.5, 
                          fontWeight: FontWeight.w900, 
                          color: total == 0 ? const Color(0xFF10B981) : const Color(0xFF0F172A)
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                        ),
                        child: Text(
                          'x$qty',
                          style: const TextStyle(
                            fontSize: 11, 
                            fontWeight: FontWeight.w800, 
                            color: Color(0xFF475569)
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> wo) {
    final tech = wo['technician'] as Map<String, dynamic>?;
    final createdAt = wo['createdAt'] as String?;
    final scheduledTime = wo['scheduledTime'] as String?;
    final completedAt = wo['completedAt'] as String?;
    final estimatedHours = wo['estimatedHours'] as num?;

    Widget timelineItem({
      required String title,
      required String? time,
      required bool isCompleted,
      required IconData icon,
      required Color color,
      bool isLast = false,
    }) {
      if (time == null) return const SizedBox.shrink();
      final formattedTime = _safeFormatDate(time);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? color.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: isCompleted ? color : const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: Icon(icon, size: 12, color: isCompleted ? color : const Color(0xFF64748B)),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 24,
                  color: isCompleted ? color.withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isCompleted ? FontWeight.w800 : FontWeight.w600,
                    color: isCompleted ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      );
    }

    return _Card(
      title: 'Thông Tin Phiếu',
      icon: Icons.info_outline_rounded,
      iconColor: const Color(0xFF8B5CF6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Technician Profile
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.engineering_rounded, size: 18, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kỹ thuật viên thực hiện',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tech?['name'] ?? 'Chưa phân công',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: tech != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          
          // Timeline Milestones
          Column(
            children: [
              timelineItem(
                title: 'Khởi tạo phiếu',
                time: createdAt,
                isCompleted: true,
                icon: Icons.create_new_folder_rounded,
                color: const Color(0xFF8B5CF6),
              ),
              if (estimatedHours != null)
                timelineItem(
                  title: 'Thời gian sửa chữa ước tính ($estimatedHours giờ)',
                  time: scheduledTime,
                  isCompleted: completedAt == null,
                  icon: Icons.timer_outlined,
                  color: const Color(0xFFD97706),
                ),
              timelineItem(
                title: 'Dự kiến hoàn thành lúc',
                time: completedAt == null ? scheduledTime : null,
                isCompleted: false,
                icon: Icons.alarm_rounded,
                color: const Color(0xFF3B82F6),
              ),
              timelineItem(
                title: 'Đã hoàn thành bàn giao',
                time: completedAt,
                isCompleted: true,
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosCard(Map<String, dynamic> wo) {
    final photos = (wo['photos'] as List<dynamic>? ?? []);
    
    // Filter photos based on photoType
    final intakePhotos = photos.where((p) {
      final type = (p as Map<String, dynamic>)['photoType'];
      return type == null || type == 'INTAKE';
    }).toList();
    
    final afterRepairPhotos = photos.where((p) {
      final type = (p as Map<String, dynamic>)['photoType'];
      return type == 'AFTER_REPAIR';
    }).toList();

    final currentPhotos = _selectedPhotoTab == 0 ? intakePhotos : afterRepairPhotos;

    return _Card(
      title: 'Hình Ảnh Xe',
      icon: Icons.photo_library_outlined,
      iconColor: const Color(0xFF6B7280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented tab switches
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPhotoTabItem(
                    label: 'Tiếp Nhận (${intakePhotos.length})',
                    isSelected: _selectedPhotoTab == 0,
                    onTap: () => setState(() => _selectedPhotoTab = 0),
                  ),
                ),
                Expanded(
                  child: _buildPhotoTabItem(
                    label: 'Sau Sửa (${afterRepairPhotos.length})',
                    isSelected: _selectedPhotoTab == 1,
                    onTap: () => setState(() => _selectedPhotoTab = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (currentPhotos.isEmpty)
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_outlined, color: Color(0xFF94A3B8), size: 28),
                    SizedBox(height: 8),
                    Text(
                      'Chưa có ảnh nào',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: currentPhotos.length,
                itemBuilder: (_, i) {
                  final url = (currentPhotos[i] as Map<String, dynamic>)['photoUrl'] ?? '';
                  return GestureDetector(
                    onTap: () => _showFullscreenImage(url),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFF1F5F9),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.network(
                          url, 
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Color(0xFF94A3B8),
                              size: 24,
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
    );
  }

  Widget _buildPhotoTabItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullscreenImage(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              type: MaterialType.circle,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(Map<String, dynamic> wo) {
    final services = (wo['services'] as List<dynamic>? ?? []);
    final parts = (wo['partsUsed'] as List<dynamic>? ?? []);

    final serviceTotal = services.fold<double>(0, (sum, s) {
      return sum + ((s['price'] as num?)?.toDouble() ?? 0);
    });
    final partsTotal = parts.fold<double>(0, (sum, p) {
      final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
      final price = (p['unitPrice'] as num?)?.toDouble() ?? 0;
      return sum + qty * price;
    });
    
    final rawTotal = serviceTotal + partsTotal;
    final total = wo['totalPrice'] != null
        ? (wo['totalPrice'] as num).toDouble()
        : rawTotal;
        
    final discount = wo['pointsDiscount'] as num? ?? 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Deep Slate
            Color(0xFF064E3B), // Deep Emerald/Forest green (Xanh EV theme)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.3),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (serviceTotal > 0)
            _TotalRow('Tiền công dịch vụ', serviceTotal, light: true),
          if (partsTotal > 0)
            _TotalRow('Chi phí phụ tùng', partsTotal, light: true),
          if (discount > 0)
            _TotalRow('Giảm giá điểm thưởng', -discount.toDouble(), light: true),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: List.generate(
                25,
                (index) => Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ),
          
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TỔNG CỘNG',
                    style: TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.white,
                      letterSpacing: 0.5
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Đã bao gồm VAT & Bảo hành',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _formatCurrency(total),
                style: const TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w900, 
                  color: Colors.white,
                  letterSpacing: -0.5
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyCard(Map<String, dynamic> wo) {
    final vehicle = wo['vehicle'] as Map<String, dynamic>? ?? {};
    final owner = vehicle['owner'] as Map<String, dynamic>? ?? {};
    final points = owner['loyaltyPoints'] as int? ?? 0;
    final alreadyRedeemed = wo['pointsRedeemed'] as int? ?? 0;
    final discount = wo['pointsDiscount'] as num? ?? 0;
    final status = (wo['status'] ?? '') as String;
    if (points == 0 && alreadyRedeemed == 0) return const SizedBox.shrink();

    // Available points card choices
    final chipValues = [50, 100, 200];

    return _Card(
      title: 'Điểm thưởng',
      icon: Icons.stars_rounded,
      iconColor: const Color(0xFFD97706),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // VIP Loyalty pass layout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1E293B), // Premium dark slate grey
                  Color(0xFF0B2E24), // Premium deep teal-green
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35), // gold border pops more
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF052E16).withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: -3,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top-right background design coin circle
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.stars_rounded,
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'XANH EV REWARDS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                            letterSpacing: 1.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), width: 1),
                          ),
                          child: const Text(
                            'MEMBER',
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$points',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'điểm khả dụng',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA7F3D0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Giá trị quy đổi: ~${_formatCurrency(points * 1000)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (alreadyRedeemed > 0) ...[
            const SizedBox(height: 16),
            // Voucher style applied points card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đã áp dụng giảm giá điểm thưởng',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dùng $alreadyRedeemed điểm (Khấu trừ -${_formatCurrency(discount)})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (points > 0 && status != 'PAID') ...[
            const SizedBox(height: 16),
            const Text(
              'ĐỔI ĐIỂM TIẾT KIỆM HÓA ĐƠN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: TextField(
                      controller: _pointsCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        // Triggers the ValueListenableBuilder listener
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập số điểm cần dùng...',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B).withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                        isDense: true,
                        prefixIcon: const Icon(
                          Icons.stars_rounded,
                          size: 18,
                          color: Color(0xFFD97706),
                        ),
                        suffixIcon: TextButton(
                          onPressed: () {
                            _pointsCtrl.text = points.toString();
                            _pointsCtrl.selection = TextSelection.fromPosition(
                              TextPosition(offset: _pointsCtrl.text.length),
                            );
                            // Refresh layout state to update live calculations
                            (context as Element).markNeedsBuild();
                          },
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Tối đa',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD97706),
                        Color(0xFFB45309),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB45309).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _redeeming ? null : _redeemPoints,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _redeeming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Dùng',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            
            // Quick choice chips
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...chipValues.where((val) => val <= points).map((val) {
                  return ChoiceChip(
                    label: Text(
                      '$val điểm',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    selected: false,
                    onSelected: (_) {
                      _pointsCtrl.text = val.toString();
                      _pointsCtrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: _pointsCtrl.text.length),
                      );
                      (context as Element).markNeedsBuild();
                    },
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: const TextStyle(color: Color(0xFF334155)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  );
                }),
              ],
            ),
            
            // ValueListenableBuilder for live calculation
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _pointsCtrl,
              builder: (context, val, _) {
                final entered = int.tryParse(val.text.trim()) ?? 0;
                if (entered <= 0) return const SizedBox.shrink();
                
                final isExceeded = entered > points;
                final calculation = entered * 1000;
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: isExceeded
                      ? const Row(
                          children: [
                            Icon(Icons.error_outline_rounded, size: 13, color: Color(0xFFBA1A1A)),
                            SizedBox(width: 4),
                            Text(
                              'Số điểm vượt quá số lượng khả dụng!',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFBA1A1A),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text(
                              'Giảm giá hóa đơn: -${_formatCurrency(calculation)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard(Map<String, dynamic> wo) {
    final notes = wo['notes'] as String? ?? '';
    if (notes.trim().isEmpty) return const SizedBox.shrink();
    return _Card(
      title: 'Ghi Chú Dịch Vụ',
      icon: Icons.speaker_notes_rounded,
      iconColor: const Color(0xFF64748B),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          notes,
          style: const TextStyle(
            fontSize: 13, 
            color: Color(0xFF334155), 
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    final actions = _getActions(status);
    if (actions.isEmpty && status != 'COMPLETED') return const SizedBox.shrink();

    return Column(
      children: [
        // Print button only when completed or paid
        if (status == 'COMPLETED' || status == 'PAID')
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _showPrintPreview,
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('Xem & In Phiếu'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF006E2F),
                side: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            ),
          ),
        ...actions.map((action) => Padding(
          padding: const EdgeInsets.only(top: 10),
              child: _isUpdating
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF006E2F)))
                  : Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006E2F), Color(0xFF15803D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF006E2F).withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: () => _showConfirmDialog(action.status),
                        icon: Icon(action.icon, size: 18),
                        label: Text(
                          action.label,
                          style: const TextStyle(letterSpacing: 0.3),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
        )),
        if (status != 'CANCELLED' && status != 'COMPLETED' && status != 'PAID')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                onPressed: () => _showConfirmDialog('CANCELLED'),
                icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFBA1A1A)),
                label: const Text(
                  'Hủy Phiếu Sửa Chữa',
                  style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<_ActionItem> _getActions(String status) {
    return switch (status) {
      'PENDING' => [
          _ActionItem('Tiếp nhận', 'INSPECTION', Icons.fact_check, const Color(0xFF6D28D9)),
        ],
      'INSPECTION' => [
          _ActionItem('Bắt đầu xử lý', 'IN_PROGRESS', Icons.play_arrow, const Color(0xFF0058BE)),
        ],
      'IN_PROGRESS' => [
          _ActionItem('Xác nhận hoàn tất', 'COMPLETED', Icons.check_circle, const Color(0xFF22C55E)),
        ],
      'COMPLETED' => [
          _ActionItem('Xác nhận thanh toán', 'PAID', Icons.payments, const Color(0xFF006E2F)),
        ],
      _ => [],
    };
  }

  String _statusLabel(String s) => switch (s) {
    'PENDING' => 'Chờ xử lý',
    'INSPECTION' => 'Kiểm tra',
    'IN_PROGRESS' => 'Đang làm',
    'COMPLETED' => 'Hoàn tất',
    'PAID' => 'Đã thanh toán',
    'CANCELLED' => 'Đã hủy',
    _ => s,
  };

  IconData _statusIcon(String s) => switch (s) {
    'INSPECTION' => Icons.fact_check,
    'IN_PROGRESS' => Icons.play_arrow,
    'COMPLETED' => Icons.check_circle,
    'PAID' => Icons.payments,
    'CANCELLED' => Icons.cancel,
    _ => Icons.info,
  };

  Color _statusColor(String s) => switch (s) {
    'PENDING' => const Color(0xFFB45309),
    'INSPECTION' => const Color(0xFF6D28D9),
    'IN_PROGRESS' => const Color(0xFF0058BE),
    'COMPLETED' || 'PAID' => const Color(0xFF006E2F),
    'CANCELLED' => const Color(0xFFBA1A1A),
    _ => const Color(0xFF6B7280),
  };

  String _formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount);
  }
}

/// Safely resolve/rewrite local image URLs pointing to emulator loopback
String _resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  try {
    final dio = GetIt.instance<Dio>();
    final baseUri = Uri.parse(dio.options.baseUrl);
    final targetUri = Uri.parse(url);
    if (targetUri.host == '10.0.2.2' && baseUri.host != '10.0.2.2') {
      return url.replaceAll('10.0.2.2', baseUri.host);
    }
  } catch (_) {}
  return url;
}


// ─────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────

/// Safely parse datetime string - handles ISO format and time-only "HH:mm"
String _safeFormatDate(String? raw, {String fallback = 'N/A'}) {
  if (raw == null) return fallback;
  try {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(raw));
  } catch (_) {
    return raw; // return as-is if not parseable (e.g. "14:00")
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _Card({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: iconColor.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withValues(alpha: 0.14),
                      iconColor.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10), // Squircle style
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}


class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool light;
  const _TotalRow(this.label, this.amount, {this.light = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: light ? FontWeight.w500 : FontWeight.w800,
              color: light ? Colors.white.withValues(alpha: 0.7) : Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: light ? FontWeight.w500 : FontWeight.w800,
              color: light ? Colors.white.withValues(alpha: 0.7) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'PENDING' => ('Chờ xử lý', const Color(0xFFD97706)),
      'IN_PROGRESS' => ('Đang làm', const Color(0xFF2563EB)),
      'INSPECTION' => ('Kiểm tra', const Color(0xFF7C3AED)),
      'COMPLETED' => ('Hoàn tất', const Color(0xFF059669)),
      'PAID' => ('Đã TT', const Color(0xFF059669)),
      'CANCELLED' => ('Đã hủy', const Color(0xFFDC2626)),
      _ => (status, const Color(0xFF6B7280)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5, 
              fontWeight: FontWeight.w800, 
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Print Preview Sheet
// ─────────────────────────────────────────────────────────────

class _PrintPreviewSheet extends StatelessWidget {
  final Map<String, dynamic> workOrder;
  const _PrintPreviewSheet({required this.workOrder});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final wo = workOrder;
    final vehicle = wo['vehicle'] as Map<String, dynamic>? ?? {};
    final owner = vehicle['owner'] as Map<String, dynamic>? ?? {};
    final services = (wo['services'] as List<dynamic>? ?? []);
    final parts = (wo['partsUsed'] as List<dynamic>? ?? []);
    final total = wo['totalPrice'] as num? ?? 0;
    final status = (wo['status'] ?? '') as String;
    
    final serviceTotal = services.fold<double>(0.0, (sum, s) => sum + ((s['price'] as num?)?.toDouble() ?? 0.0));
    final partsTotal = parts.fold<double>(0.0, (sum, p) {
      final qty = p['quantity'] as num? ?? 0;
      final price = p['unitPrice'] as num? ?? 0;
      return sum + qty * price;
    });
    final rawTotal = serviceTotal + partsTotal;
    final discount = wo['pointsDiscount'] as num? ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F7F2), Color(0xFFF0F4F8)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFB0BEC5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006E2F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long, color: Color(0xFF006E2F), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xem trước phiếu',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Kiểm tra trước khi in',
                          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chức năng in sẽ được cập nhật sớm'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('In Phiếu'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006E2F),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            // Invoice content
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Top green accent bar
                          Container(
                            height: 6,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF006E2F), Color(0xFF22C55E)],
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                          ),
                          // Shop header
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
                            child: Column(
                              children: [
                                Text(
                                  'NĂNG LƯỢNG SẠCH',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF006E2F),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Dịch vụ bảo trì xe điện',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'ĐT: 1900-xxxx  ·  www.nanglungsach.vn',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          ),
                      // Dashed divider
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: CustomPaint(
                          painter: _DashedLinePainter(color: const Color(0xFFE5E7EB)),
                          child: const SizedBox(height: 1, width: double.infinity),
                        ),
                      ),
                      // Order number + status
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PHIẾU SỬA CHỮA',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF374151), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    wo['orderNumber'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF006E2F),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _PrintStatusBadge(status: status),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Customer info card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F7F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD1E7D9)),
                          ),
                          child: Column(
                            children: [
                              _PrintInfoRow(icon: Icons.directions_car_rounded, label: 'Biển số', value: vehicle['licensePlate'] ?? 'N/A'),
                              const SizedBox(height: 8),
                              _PrintInfoRow(icon: Icons.person_outline_rounded, label: 'Khách hàng', value: owner['name'] ?? 'N/A'),
                              const SizedBox(height: 8),
                              _PrintInfoRow(icon: Icons.phone_outlined, label: 'Điện thoại', value: owner['phoneNumber'] ?? 'N/A'),
                              const SizedBox(height: 8),
                              _PrintInfoRow(
                                icon: Icons.access_time_rounded,
                                label: 'Ngày tạo',
                                value: wo['createdAt'] != null ? _safeFormatDate(wo['createdAt'] as String?) : 'N/A',
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Services section
                      if (services.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          child: _buildSectionHeader('DỊCH VỤ', Icons.build_outlined),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                          child: Column(
                            children: services.map((s) => _buildItemRow(
                              label: _serviceLabel(s['serviceType'] as String?),
                              price: s['price'],
                              fmt: fmt,
                            )).toList(),
                          ),
                        ),
                      ],
                      // Parts section
                      if (parts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          child: _buildSectionHeader('PHỤ TÙNG', Icons.inventory_2_outlined),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                          child: Column(
                            children: parts.map((p) {
                              final part = p as Map<String, dynamic>;
                              final partInfo = part['part'] as Map<String, dynamic>? ?? {};
                              final qty = part['quantity'] as num? ?? 0;
                              final unitPrice = part['unitPrice'] as num? ?? 0;
                              return _buildItemRow(
                                label: '${partInfo['partName'] ?? 'N/A'}  x$qty',
                                price: qty * unitPrice,
                                fmt: fmt,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      // Total
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: CustomPaint(
                          painter: _DashedLinePainter(color: const Color(0xFF006E2F).withValues(alpha: 0.3)),
                          child: const SizedBox(height: 1, width: double.infinity),
                        ),
                      ),
                      if (discount > 0) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                          child: Row(
                            children: [
                              const Text(
                                'Tạm tính',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                fmt.format(rawTotal),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                          child: Row(
                            children: [
                              const Text(
                                'Giảm giá điểm thưởng',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFBA1A1A),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '-${fmt.format(discount)}',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFBA1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                          child: CustomPaint(
                            painter: _DashedLinePainter(color: const Color(0xFFE5E7EB)),
                            child: const SizedBox(height: 1, width: double.infinity),
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                        child: Row(
                          children: [
                            const Text(
                              'TỔNG CỘNG',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF374151),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              fmt.format(total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF006E2F),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Thank you
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F7F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Cảm ơn quý khách đã tin tưởng sử dụng dịch vụ!',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                // Watermark overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _WatermarkPainter(),
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


  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF006E2F).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF006E2F)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF374151),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow({required String label, num? price, required NumberFormat fmt}) {
    final isFree = price == null || price == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
          if (price != null)
            Text(
              isFree ? 'Bảo hành' : fmt.format(price),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isFree ? const Color(0xFF006E2F) : const Color(0xFF111827),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrintStatusBadge extends StatelessWidget {
  final String status;
  const _PrintStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'PENDING' => ('Chờ xử lý', const Color(0xFFB45309)),
      'INSPECTION' => ('Kiểm tra', const Color(0xFF6D28D9)),
      'IN_PROGRESS' => ('Đang làm', const Color(0xFF0058BE)),
      'COMPLETED' => ('Hoàn tất', const Color(0xFF006E2F)),
      'PAID' => ('Đã TT', const Color(0xFF006E2F)),
      'CANCELLED' => ('Đã hủy', const Color(0xFFBA1A1A)),
      _ => (status, const Color(0xFF6B7280)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _PrintInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PrintInfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF006E2F)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.3)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final smallText = TextPainter(
      text: TextSpan(
        text: 'nangluongsach',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF006E2F).withValues(alpha: 0.035),
          letterSpacing: 1.5,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    smallText.layout();

    final largeText = TextPainter(
      text: TextSpan(
        text: 'NLS',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF006E2F).withValues(alpha: 0.07),
          letterSpacing: 4,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    largeText.layout();

    const angle = -0.4;
    const smallSpacing = 140.0;
    const largeSpacing = 200.0;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);

    // Large "NLS" watermark across the sheet
    for (double y = -size.height; y < size.height * 1.5; y += largeSpacing) {
      for (double x = -size.width; x < size.width * 1.5; x += largeSpacing) {
        largeText.paint(canvas, Offset(x, y));
      }
    }

    // Small "nangluongsach" watermark between large ones
    for (double y = -size.height + smallSpacing / 2;
        y < size.height * 1.5;
        y += smallSpacing) {
      for (double x = -size.width + smallSpacing / 2;
          x < size.width * 1.5;
          x += smallSpacing) {
        smallText.paint(canvas, Offset(x, y));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



// Helper
class _ActionItem {
  final String label;
  final String status;
  final IconData icon;
  final Color color;
  const _ActionItem(this.label, this.status, this.icon, this.color);
}

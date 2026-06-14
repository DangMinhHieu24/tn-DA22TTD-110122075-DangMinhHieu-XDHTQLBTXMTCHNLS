import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = GetIt.instance<Dio>();
      final res = await dio.get('/work-orders/${widget.workOrderId}');
      setState(() {
        _workOrder = res.data['data'] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
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
            Text('Xác nhận', style: const TextStyle(fontSize: 18)),
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
      backgroundColor: const Color(0xFFF0F4F8),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVehicleCard(wo),
                const SizedBox(height: 16),
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
                if (wo['notes'] != null) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(wo),
                ],
                const SizedBox(height: 16),
                _buildActionButtons(status),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> wo, String status) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 14),
      color: const Color(0xFFF0F4F8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF374151)),
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
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: Color(0xFF111827), letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  'Phiếu Sửa Chữa',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          // Badge mới có dot + refresh
          Row(
            children: [
              _StatusBadge(status: status),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _fetchDetail,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF6B7280)),
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
    return _Card(
      title: 'Thông Tin Xe & Khách',
      icon: Icons.two_wheeler,
      iconColor: const Color(0xFF006E2F),
      child: Column(
        children: [
          _DetailRow('Biển số', vehicle['licensePlate'] ?? 'N/A', bold: true),
          _DetailRow('Model', vehicle['vehicleModel'] ?? vehicle['model'] ?? 'N/A'),
          _DetailRow('Số khung', vehicle['chassisNumber'] ?? 'N/A'),
          const Divider(height: 20),
          _DetailRow('Chủ xe', owner['name'] ?? 'N/A', bold: true),
          _DetailRow('Điện thoại', owner['phoneNumber'] ?? 'N/A',
              icon: Icons.phone, iconColor: const Color(0xFF0058BE)),
          if (owner['email'] != null)
            _DetailRow('Email', owner['email'], icon: Icons.email_outlined),
        ],
      ),
    );
  }

  Widget _buildServicesCard(Map<String, dynamic> wo) {
    final services = (wo['services'] as List<dynamic>? ?? []);
    return _Card(
      title: 'Dịch Vụ Thực Hiện',
      icon: Icons.build,
      iconColor: const Color(0xFF0058BE),
      child: services.isEmpty
          ? const Text('Chưa có dịch vụ', style: TextStyle(color: Color(0xFF9CA3AF)))
          : Column(
              children: services.asMap().entries.map((e) {
                final s = e.value as Map<String, dynamic>;
                final isDone = s['isDone'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF006E2F)
                              : const Color(0xFFE5E7EB),
                        ),
                        child: Icon(
                          isDone ? Icons.check : Icons.circle_outlined,
                          size: 14,
                          color: isDone ? Colors.white : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _serviceLabel(s['serviceType'] as String?),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDone
                                    ? const Color(0xFF006E2F)
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                            if (s['description'] != null)
                              Text(
                                s['description'],
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                          ],
                        ),
                      ),
                      if (s['price'] != null)
                        Text(
                          _formatCurrency(s['price']),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF006E2F),
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
      icon: Icons.inventory_2,
      iconColor: const Color(0xFFB45309),
      child: Column(
        children: [
          // Header
          Row(
            children: const [
              Expanded(child: Text('Phụ tùng', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600))),
              SizedBox(width: 8),
              Text('SL', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
              SizedBox(width: 16),
              SizedBox(width: 80, child: Text('Thành tiền', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600))),
            ],
          ),
          const Divider(height: 12),
          ...parts.map((p) {
            final part = p as Map<String, dynamic>;
            final partInfo = part['part'] as Map<String, dynamic>? ?? {};
            final qty = part['quantity'] as num? ?? 0;
            final unitPrice = part['unitPrice'] as num? ?? 0;
            final total = qty * unitPrice;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      partInfo['partName'] ?? 'N/A',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('x$qty', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _formatCurrency(total),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    ),
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
    final createdAt = _safeFormatDate(wo['createdAt'] as String?);
    return _Card(
      title: 'Thông Tin Phiếu',
      icon: Icons.info_outline,
      iconColor: const Color(0xFF6D28D9),
      child: Column(
        children: [
          _DetailRow('Kỹ thuật viên',
              tech?['name'] ?? 'Chưa phân công',
              bold: tech != null,
              icon: Icons.engineering,
              iconColor: const Color(0xFF0058BE)),
          _DetailRow('Ngày tạo', createdAt, icon: Icons.calendar_today_outlined),
          if (wo['estimatedHours'] != null)
            _DetailRow('Thời gian ước tính', '${wo['estimatedHours']} giờ'),
          if (wo['scheduledTime'] != null)
            _DetailRow('Hẹn xong lúc', _safeFormatDate(wo['scheduledTime'] as String?)),
          if (wo['completedAt'] != null)
            _DetailRow('Hoàn thành lúc', _safeFormatDate(wo['completedAt'] as String?),
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFF006E2F)),
        ],
      ),
    );
  }

  Widget _buildPhotosCard(Map<String, dynamic> wo) {
    final photos = (wo['photos'] as List<dynamic>? ?? []);
    return _Card(
      title: 'Ảnh Xe',
      icon: Icons.photo_library_outlined,
      iconColor: const Color(0xFF6B7280),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          itemBuilder: (_, i) {
            final url = (photos[i] as Map<String, dynamic>)['photoUrl'] ?? '';
            return Container(
              margin: const EdgeInsets.only(right: 8),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFE5E7EB),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(url, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined,
                        color: Color(0xFF9CA3AF))),
              ),
            );
          },
        ),
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
    final total = wo['totalPrice'] != null
        ? (wo['totalPrice'] as num).toDouble()
        : serviceTotal + partsTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (serviceTotal > 0)
            _TotalRow('Dịch vụ', serviceTotal, light: true),
          if (partsTotal > 0)
            _TotalRow('Phụ tùng', partsTotal, light: true),
          if (serviceTotal > 0 || partsTotal > 0)
            const Divider(color: Colors.white24, height: 16),
          Row(
            children: [
              const Text('TỔNG CỘNG',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              Text(
                _formatCurrency(total),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(Map<String, dynamic> wo) {
    return _Card(
      title: 'Ghi Chú',
      icon: Icons.notes,
      iconColor: const Color(0xFF6B7280),
      child: Text(
        wo['notes'] ?? '',
        style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.5),
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
          OutlinedButton.icon(
            onPressed: _showPrintPreview,
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('Xem & In Phiếu'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF16A34A),
              side: const BorderSide(color: Color(0xFF16A34A)),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ...actions.map((action) => Padding(
          padding: const EdgeInsets.only(top: 10),
              child: _isUpdating
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF15803D)))
                  : Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006E2F), Color(0xFF15803D)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FilledButton.icon(
                        onPressed: () => _showConfirmDialog(action.status),
                        icon: Icon(action.icon, size: 18),
                        label: Text(action.label),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
        )),
        if (status != 'CANCELLED' && status != 'COMPLETED' && status != 'PAID')
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton.icon(
              onPressed: () => _showConfirmDialog('CANCELLED'),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Hủy Phiếu'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFBA1A1A),
                side: const BorderSide(color: Color(0xFFBA1A1A)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon tròn thay vì vuông
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final IconData? icon;
  final Color? iconColor;

  const _DetailRow(this.label, this.value,
      {this.bold = false, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label với icon
          SizedBox(
            width: 130,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: iconColor ?? const Color(0xFF374151)),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Value
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF111827),
              ),
            ),
          ),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: light ? Colors.white70 : Colors.white)),
          const Spacer(),
          Text(
            NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount),
            style: TextStyle(
                fontSize: 13,
                fontWeight: light ? FontWeight.w400 : FontWeight.w700,
                color: light ? Colors.white70 : Colors.white),
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
      'PENDING' => ('Chờ xử lý', const Color(0xFFB45309)),
      'IN_PROGRESS' => ('Đang làm', const Color(0xFF0058BE)),
      'INSPECTION' => ('Kiểm tra', const Color(0xFF6D28D9)),
      'COMPLETED' => ('Hoàn tất', const Color(0xFF006E2F)),
      'PAID' => ('Đã TT', const Color(0xFF006E2F)),
      'CANCELLED' => ('Đã hủy', const Color(0xFFBA1A1A)),
      _ => (status, const Color(0xFF6B7280)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
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
                child: Container(
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                        child: Column(
                          children: [
                            const Text(
                              'NĂNG LƯỢNG SẠCH',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF006E2F),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Dịch vụ bảo trì xe điện',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 2),
                            const Text(
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
              fmt.format(price),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
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



// Helper
class _ActionItem {
  final String label;
  final String status;
  final IconData icon;
  final Color color;
  const _ActionItem(this.label, this.status, this.icon, this.color);
}

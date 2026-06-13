import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

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
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF006E2F)))
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, size: 20),
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
                    fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Phiếu Sửa Chữa',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          _StatusBadge(status: status),
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
                              s['serviceType'] ?? '',
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
          colors: [Color(0xFF006E2F), Color(0xFF15803D)],
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
        // Print button always visible
        OutlinedButton.icon(
          onPressed: _showPrintPreview,
          icon: const Icon(Icons.print_outlined, size: 18),
          label: const Text('Xem & In Phiếu'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF006E2F),
            side: const BorderSide(color: Color(0xFF006E2F)),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        ...actions.map((action) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _isUpdating
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF006E2F)))
              : FilledButton.icon(
                  onPressed: () => _showConfirmDialog(action.status),
                  icon: Icon(action.icon, size: 18),
                  label: Text(action.label),
                  style: FilledButton.styleFrom(
                    backgroundColor: action.color,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          _ActionItem('Bắt đầu xử lý', 'IN_PROGRESS', Icons.play_arrow, const Color(0xFF0058BE)),
        ],
      'IN_PROGRESS' => [
          _ActionItem('Xác nhận hoàn tất', 'COMPLETED', Icons.check_circle, const Color(0xFF006E2F)),
        ],
      'COMPLETED' => [
          _ActionItem('Xác nhận thanh toán', 'PAID', Icons.payments, const Color(0xFF006E2F)),
        ],
      _ => [],
    };
  }

  String _statusLabel(String s) => switch (s) {
    'PENDING' => 'Chờ xử lý',
    'IN_PROGRESS' => 'Đang làm',
    'COMPLETED' => 'Hoàn tất',
    'PAID' => 'Đã thanh toán',
    'CANCELLED' => 'Đã hủy',
    _ => s,
  };

  IconData _statusIcon(String s) => switch (s) {
    'IN_PROGRESS' => Icons.play_arrow,
    'COMPLETED' => Icons.check_circle,
    'PAID' => Icons.payments,
    'CANCELLED' => Icons.cancel,
    _ => Icons.info,
  };

  Color _statusColor(String s) => switch (s) {
    'PENDING' => const Color(0xFFB45309),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: iconColor ?? const Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF1F2937),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Xem trước phiếu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  // Share/Print button
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
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('In Phiếu'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006E2F),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Print content
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop header
                      const Center(
                        child: Column(
                          children: [
                            Text('NĂNG LƯỢNG SẠCH',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF006E2F))),
                            Text('Dịch vụ bảo trì xe điện',
                                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                            SizedBox(height: 4),
                            Text('ĐT: 1900-xxxx | www.nanglungsach.vn',
                                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      Center(
                        child: Column(
                          children: [
                            const Text('PHIẾU SỬA CHỮA',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            Text(
                              wo['orderNumber'] ?? '',
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF006E2F),
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      _PrintRow('Biển số:', vehicle['licensePlate'] ?? 'N/A'),
                      _PrintRow('Khách hàng:', owner['name'] ?? 'N/A'),
                      _PrintRow('Điện thoại:', owner['phoneNumber'] ?? 'N/A'),
                      _PrintRow('Ngày tạo:',
                          wo['createdAt'] != null
                              ? _safeFormatDate(wo['createdAt'] as String?)
                              : 'N/A'),
                      const SizedBox(height: 12),
                      const Text('DỊCH VỤ:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      ...services.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 13)),
                            Expanded(child: Text(s['serviceType'] ?? '', style: const TextStyle(fontSize: 13))),
                            if (s['price'] != null)
                              Text(fmt.format(s['price']),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                      if (parts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('PHỤ TÙNG:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        ...parts.map((p) {
                          final part = p as Map<String, dynamic>;
                          final partInfo = part['part'] as Map<String, dynamic>? ?? {};
                          final qty = part['quantity'] as num? ?? 0;
                          final unitPrice = part['unitPrice'] as num? ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 13)),
                                Expanded(child: Text('${partInfo['partName'] ?? 'N/A'} x$qty',
                                    style: const TextStyle(fontSize: 13))),
                                Text(fmt.format(qty * unitPrice),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        children: [
                          const Text('TỔNG CỘNG:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text(fmt.format(total),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF006E2F))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Cảm ơn quý khách đã tin tưởng sử dụng dịch vụ!',
                          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
}

class _PrintRow extends StatelessWidget {
  final String label;
  final String value;
  const _PrintRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// Helper
class _ActionItem {
  final String label;
  final String status;
  final IconData icon;
  final Color color;
  const _ActionItem(this.label, this.status, this.icon, this.color);
}

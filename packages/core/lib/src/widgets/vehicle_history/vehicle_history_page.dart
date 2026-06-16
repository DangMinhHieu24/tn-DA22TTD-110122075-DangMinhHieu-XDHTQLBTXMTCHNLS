import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:core/core.dart';

class VehicleHistoryPage extends StatefulWidget {
  final String licensePlate;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? ownerName;
  final String? ownerPhone;
  final List<WorkHistoryItem> historyItems;

  const VehicleHistoryPage({
    super.key,
    required this.licensePlate,
    this.vehicleModel,
    this.vehicleColor,
    this.ownerName,
    this.ownerPhone,
    required this.historyItems,
  });

  @override
  State<VehicleHistoryPage> createState() => _VehicleHistoryPageState();
}

class _VehicleHistoryPageState extends State<VehicleHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final int _itemsPerPage = 10;
  int _displayCount = 10;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  static const _kGreen = Color(0xFF006E2F);
  static const _kBg = Color(0xFFF8FAFB);

  List<WorkHistoryItem> get _filteredItems {
    var items = widget.historyItems;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((item) {
        return (item.orderNumber.toLowerCase().contains(q)) ||
            (item.notes?.toLowerCase().contains(q) ?? false) ||
            (item.description?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    if (_startDate != null || _endDate != null) {
      items = items.where((item) {
        if (item.createdAt == null) return false;
        final d = item.createdAt!;
        if (_startDate != null && d.isBefore(_startDate!.subtract(const Duration(days: 1)))) return false;
        if (_endDate != null && d.isAfter(_endDate!.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();
    }
    return items;
  }

  List<WorkHistoryItem> get _displayedItems {
    return _filteredItems.take(_displayCount).toList();
  }

  bool get _hasMore => _displayCount < _filteredItems.length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFF9800);
      case 'IN_PROGRESS':
        return const Color(0xFF3B82F6);
      case 'INSPECTION':
        return const Color(0xFF9C27B0);
      case 'COMPLETED':
        return const Color(0xFF4CAF50);
      case 'PAID':
        return const Color(0xFF006E2F);
      case 'CANCELLED':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'PENDING':
        return 'CHỜ XỬ LÝ';
      case 'IN_PROGRESS':
        return 'ĐANG THỰC HIỆN';
      case 'INSPECTION':
        return 'KIỂM TRA';
      case 'COMPLETED':
        return 'HOÀN THÀNH';
      case 'PAID':
        return 'ĐÃ THANH TOÁN';
      case 'CANCELLED':
        return 'ĐÃ HỦY';
      default:
        return 'KHÔNG RÕ';
    }
  }

  String _formatDate(DateTime date) {
    final d = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
    final t = '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _kGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _displayCount = 10;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _showExportDialog() {
    final items = _displayedItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu để xuất báo cáo.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.description_outlined, color: _kGreen),
            SizedBox(width: 8),
            Text('Xuất báo cáo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Chọn hình thức xuất báo cáo sao kê lịch sử sửa chữa.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _generateAndPreview(items);
            },
            child: const Text('Xem trước & In', style: TextStyle(color: _kGreen, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _generateAndShare(items);
            },
            child: const Text('Chia sẻ file PDF', style: TextStyle(color: _kGreen, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _loadFont() async {
    try {
      return (await rootBundle.load('assets/fonts/Roboto-Variable.ttf'))
          .buffer
          .asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _generateAndPreview(List<WorkHistoryItem> items) async {
    try {
      final fontBytes = await _loadFont();
      await Printing.layoutPdf(
        onLayout: (format) => PdfReportGenerator.generateVehicleHistoryReport(
          licensePlate: widget.licensePlate,
          vehicleModel: widget.vehicleModel,
          vehicleColor: widget.vehicleColor,
          ownerName: widget.ownerName,
          ownerPhone: widget.ownerPhone,
          items: items,
          startDate: _startDate,
          endDate: _endDate,
          fontBytes: fontBytes,
        ),
      );
    } catch (e) {
      _showExportError(e);
    }
  }

  Future<void> _generateAndShare(List<WorkHistoryItem> items) async {
    try {
      final fontBytes = await _loadFont();
      final pdf = await PdfReportGenerator.generateVehicleHistoryReport(
        licensePlate: widget.licensePlate,
        vehicleModel: widget.vehicleModel,
        vehicleColor: widget.vehicleColor,
        ownerName: widget.ownerName,
        ownerPhone: widget.ownerPhone,
        items: items,
        startDate: _startDate,
        endDate: _endDate,
        fontBytes: fontBytes,
      );
      await Printing.sharePdf(
        bytes: pdf,
        filename: 'SaoKe_${widget.licensePlate.replaceAll(RegExp(r'\s+'), '_')}.pdf',
      );
    } catch (e) {
      _showExportError(e);
    }
  }

  void _showExportError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lỗi xuất báo cáo: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF191C1E)),
        ),
        titleSpacing: 0,
        title: const Text(
          'Phiếu Sửa Chữa',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF191C1E),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _displayCount = 10;
                _searchController.clear();
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildVehicleHeader(),
          _buildSearchBar(),
          _buildDateFilterChip(),
          Expanded(child: _buildHistoryList()),
          _buildBottomSection(),
        ],
      ),
    );
  }

  // ── Vehicle Header ────────────────────────────────────────────────

  Widget _buildVehicleHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  size: 22,
                  color: _kGreen,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.licensePlate,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF191C1E),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [widget.vehicleModel, widget.vehicleColor]
                .whereType<String>()
                .join(' - '),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF3C3C3C), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF191C1E),
              ),
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm mã WO, loại dịch vụ...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6E6E6E),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                  _displayCount = 10;
                });
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _displayCount = 10;
                });
              },
              icon: const Icon(Icons.close_rounded, color: Color(0xFF3C3C3C), size: 18),
            ),
          GestureDetector(
            onTap: _pickDateRange,
            child: Icon(
              _startDate != null ? Icons.date_range_rounded : Icons.calendar_today_rounded,
              color: _startDate != null ? _kGreen : const Color(0xFF3C3C3C),
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip() {
    if (_startDate == null || _endDate == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range_rounded, size: 14, color: _kGreen),
          const SizedBox(width: 6),
          Text(
            '${_formatDateShort(_startDate!)} - ${_formatDateShort(_endDate!)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kGreen,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _clearDateFilter,
            child: const Icon(Icons.close_rounded, size: 14, color: _kGreen),
          ),
        ],
      ),
    );
  }

  // ── History List ──────────────────────────────────────────────────

  Widget _buildHistoryList() {
    final items = _displayedItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Không tìm thấy kết quả'
                  : 'Chưa có lịch sử sửa chữa',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Thử từ khóa khác'
                  : 'Lịch sử sẽ hiển thị khi có phiếu sửa chữa.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      itemCount: items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < items.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildHistoryCard(items[index], index),
          );
        }
        return _buildLoadMoreButton();
      },
    );
  }

  Widget _buildHistoryCard(WorkHistoryItem item, int index) {
    final statusColor = _getStatusColor(item.status);
    final statusText = _getStatusText(item.status);
    final description = item.description ?? item.notes ?? '';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: IntrinsicHeight(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.orderNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF191C1E),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (item.createdAt != null) ...[
                            const Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(item.createdAt!),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                          if (item.licensePlate != null) ...[
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.two_wheeler_rounded,
                              size: 13,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.licensePlate!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD1D5DB),
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Section ────────────────────────────────────────────────

  Widget _buildBottomSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showExportDialog,
          icon: const Icon(Icons.description_outlined, size: 18),
          label: const Text('Xuất báo cáo (Sao kê)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _displayCount += _itemsPerPage;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TẢI THÊM LỊCH SỬ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kGreen,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _kGreen,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

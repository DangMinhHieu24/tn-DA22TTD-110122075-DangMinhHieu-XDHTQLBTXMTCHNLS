import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'work_order_detail_page.dart';

String _serviceLabel(String? type) => switch (type) {
  'MAINTENANCE' => 'Bảo dưỡng định kỳ',
  'BATTERY_CHECK' => 'Kiểm tra pin/sạc',
  'BRAKES_TIRES' => 'Phanh & Lốp',
  'OTHER_REPAIR' => 'Sửa chữa khác',
  _ => type ?? '',
};

String _safeFormatDate(String? raw, {String fallback = ''}) {
  if (raw == null) return fallback;
  try {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(raw));
  } catch (_) {
    return raw;
  }
}

Color _statusColor(String status) => switch (status) {
      'PENDING' => const Color(0xFFB45309),
      'IN_PROGRESS' => const Color(0xFF0058BE),
      'INSPECTION' => const Color(0xFF6D28D9),
      'COMPLETED' || 'PAID' => const Color(0xFF006E2F),
      'CANCELLED' => const Color(0xFFBA1A1A),
      _ => const Color(0xFF6B7280),
    };

String _statusLabel(String status) => switch (status) {
      'PENDING' => 'Chờ xử lý',
      'IN_PROGRESS' => 'Đang làm',
      'INSPECTION' => 'Kiểm tra',
      'COMPLETED' => 'Hoàn tất',
      'PAID' => 'Đã TT',
      'CANCELLED' => 'Đã hủy',
      _ => status,
    };

class WorkOrderListPage extends StatefulWidget {
  final int initialTabIndex;
  const WorkOrderListPage({super.key, this.initialTabIndex = 0});

  @override
  State<WorkOrderListPage> createState() => _WorkOrderListPageState();
}

class _WorkOrderListPageState extends State<WorkOrderListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'newest';

  static const _tabs = [
    _StatusTab('Tất cả', null),
    _StatusTab('Chờ xử lý', 'PENDING'),
    _StatusTab('Kiểm tra', 'INSPECTION'),
    _StatusTab('Đang làm', 'IN_PROGRESS'),
    _StatusTab('Hoàn tất', 'COMPLETED'),
    _StatusTab('Đã TT', 'PAID'),
  ];

  List<Map<String, dynamic>> _workOrders = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _fetchWorkOrders();
    });
    _fetchWorkOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = GetIt.instance<Dio>();
      final status = _tabs[_tabController.index].status;
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      if (status == 'PAID') params['sortBy'] = 'paidAt';
      final response = await dio.get(
        '/work-orders',
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = (response.data['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      setState(() { _workOrders = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  int _countForStatus(String? status) {
    if (status == null) return _workOrders.length;
    return _workOrders.where((o) => o['status'] == status).length;
  }

  List<Map<String, dynamic>> get _sortedFiltered {
    var list = _workOrders.where((o) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final plate = (o['vehicle']?['licensePlate'] ?? '').toString().toLowerCase();
      final order = (o['orderNumber'] ?? '').toString().toLowerCase();
      final owner = (o['vehicle']?['owner']?['name'] ?? '').toString().toLowerCase();
      final phone = (o['vehicle']?['owner']?['phoneNumber'] ?? '').toString().toLowerCase();
      return plate.contains(q) || order.contains(q) || owner.contains(q) || phone.contains(q);
    }).toList();

    final isPaidTab = _tabs[_tabController.index].status == 'PAID';
    switch (_sortBy) {
      case 'newest':
        if (isPaidTab) {
          list.sort((a, b) => (b['paidAt'] ?? '').compareTo(a['paidAt'] ?? ''));
        } else {
          list.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
        }
      case 'oldest':
        if (isPaidTab) {
          list.sort((a, b) => (a['paidAt'] ?? '').compareTo(b['paidAt'] ?? ''));
        } else {
          list.sort((a, b) => (a['createdAt'] ?? '').compareTo(b['createdAt'] ?? ''));
        }
    }
    return list;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SortSheet(
        current: _sortBy,
        onSelect: (v) {
          setState(() => _sortBy = v);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndSort(),
          _buildTabBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 15, color: Color(0xFF334155)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phiếu Sửa Chữa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006E2F).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF006E2F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_workOrders.length} phiếu',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF006E2F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _fetchWorkOrders();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF008A3B), Color(0xFF006E2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006E2F).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search + Bộ lọc tích hợp trong 1 pill ──────────────────
  Widget _buildSearchAndSort() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            // Search field
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Tìm biển số, mã phiếu, tên KH...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w400),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.cancel, color: Color(0xFF64748B), size: 18),
                        )
                       : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  isDense: true,
                ),
              ),
            ),
            // Divider
            Container(width: 1.5, height: 20, color: const Color(0xFFCBD5E1)),
            // Bộ lọc button
            GestureDetector(
               onTap: _showSortSheet,
               child: Container(
                 color: Colors.transparent,
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(
                       Icons.tune_rounded,
                       size: 18,
                       color: _sortBy != 'newest'
                           ? const Color(0xFF006E2F)
                           : const Color(0xFF475569),
                     ),
                     const SizedBox(width: 6),
                     Text(
                       _sortBy == 'oldest' ? 'Cũ nhất' : 'Bộ lọc',
                       style: TextStyle(
                         fontSize: 13,
                         fontWeight: FontWeight.w700,
                         color: _sortBy != 'newest'
                             ? const Color(0xFF006E2F)
                             : const Color(0xFF475569),
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

  // ── Tabs dạng pill ─────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _tabs.asMap().entries.map((e) {
            final isSelected = _tabController.index == e.key;
            final count = _countForStatus(e.value.status);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _tabController.animateTo(e.key);
                _fetchWorkOrders();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF008A3B), Color(0xFF006E2F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF006E2F).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.value.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: 5,
        itemBuilder: (_, __) => const _SkeletonCard(),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFFBA1A1A)),
            ),
            const SizedBox(height: 16),
            const Text('Không thể tải dữ liệu',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 4),
            Text('Kiểm tra kết nối và thử lại',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _fetchWorkOrders,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF006E2F)),
            ),
          ],
        ),
      );
    }
    final items = _sortedFiltered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[200]),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'Không tìm thấy kết quả' : 'Chưa có phiếu nào',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF006E2F),
      onRefresh: _fetchWorkOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _WorkOrderCard(
          data: items[i],
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => WorkOrderDetailPage(workOrderId: items[i]['id']),
              ),
            );
            if (updated == true) _fetchWorkOrders();
          },
          onQuickConfirm: () => _quickUpdateStatus(items[i]),
        ),
      ),
    );
  }

  Future<void> _quickUpdateStatus(Map<String, dynamic> wo) async {
    final status = wo['status'] as String;
    final nextStatus = switch (status) {
      'PENDING' => 'INSPECTION',
      'INSPECTION' => 'IN_PROGRESS',
      'IN_PROGRESS' => 'COMPLETED',
      'COMPLETED' => 'PAID',
      _ => null,
    };
    if (nextStatus == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận', style: TextStyle(fontSize: 17)),
        content: Text('Chuyển phiếu ${wo['orderNumber']} sang "${_statusLabel(nextStatus)}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _statusColor(nextStatus)),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final dio = GetIt.instance<Dio>();
      await dio.patch('/work-orders/${wo['id']}/status', data: {'status': nextStatus});
      HapticFeedback.mediumImpact();
      _fetchWorkOrders();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cập nhật thất bại'),
          backgroundColor: Color(0xFFBA1A1A),
        ));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Work Order Card
// ─────────────────────────────────────────────────────────────

class _WorkOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onQuickConfirm;

  const _WorkOrderCard({
    required this.data,
    required this.onTap,
    required this.onQuickConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'PENDING') as String;
    final orderNumber = data['orderNumber'] ?? '';
    final plate = data['vehicle']?['licensePlate'] ?? 'N/A';
    final vehicleModel = data['vehicle']?['vehicleModel'] ?? data['vehicle']?['model'] ?? '';
    final ownerName = data['vehicle']?['owner']?['name'] ?? 'N/A';
    final techName = data['technician']?['name'] ?? 'Chưa phân công';
    final createdAt = status == 'PAID'
        ? _safeFormatDate(data['paidAt'] as String?)
        : _safeFormatDate(data['createdAt'] as String?);
    final services = (data['services'] as List<dynamic>? ?? []);
    final serviceText = services
        .map((s) => _serviceLabel(s['serviceType'] as String?))
        .where((s) => s.isNotEmpty)
        .join(' · ');

    final canConfirm = status == 'PENDING' || status == 'IN_PROGRESS' || status == 'COMPLETED';
    final nextLabel = status == 'PENDING' ? 'Bắt đầu' : status == 'IN_PROGRESS' ? 'Hoàn tất' : 'Đã TT';
    final nextColor = status == 'PENDING' ? const Color(0xFF0058BE) : const Color(0xFF006E2F);

    return Dismissible(
      key: ValueKey(data['id']),
      direction: canConfirm ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (_) async {
        onQuickConfirm();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: nextColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == 'PENDING'
                  ? Icons.play_arrow_rounded
                  : status == 'COMPLETED'
                      ? Icons.payments_rounded
                      : Icons.check_circle_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              nextLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 8,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: _statusColor(status).withValues(alpha: 0.04),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ── Left status color bar ──
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
                // ── Nội dung ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Mã phiếu + badge trạng thái
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    orderNumber,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (serviceText.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      serviceText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                        letterSpacing: 0.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadgeNew(status: status),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 2: Vehicle box - authentic license plate widget
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              // Vietnamese license plate container
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF94A3B8), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(height: 1.5, width: 24, color: const Color(0xFFBA1A1A)),
                                    const SizedBox(height: 3),
                                    Text(
                                      plate,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.electric_moped_rounded,
                                            size: 16, color: _statusColor(status)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            vehicleModel.isNotEmpty ? vehicleModel : 'Xe điện',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF334155),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Phương tiện sửa chữa',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Row 3: Khách hàng | Kỹ thuật viên (2 columns, styled cards)
                        Row(
                          children: [
                            // Customer card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_rounded,
                                        size: 15, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'KHÁCH HÀNG',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF94A3B8),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            ownerName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF334155),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tech card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.engineering_rounded,
                                        size: 15, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'KỸ THUẬT VIÊN',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF3B82F6),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            techName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1D4ED8),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Divider
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),

                        // Row 4: Thời gian + Chi tiết
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              createdAt,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            if (canConfirm)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: nextColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: nextColor.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.keyboard_double_arrow_left_rounded,
                                        size: 14, color: nextColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Vuốt: $nextLabel',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: nextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF006E2F).withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF006E2F).withValues(alpha: 0.2)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Chi tiết',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF006E2F),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 14, color: Color(0xFF006E2F)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sort Sheet
// ─────────────────────────────────────────────────────────────

class _SortSheet extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelect;
  const _SortSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('newest', Icons.arrow_downward_rounded, 'Mới nhất trước'),
      ('oldest', Icons.arrow_upward_rounded, 'Cũ nhất trước'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 5,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const Text(
            'Sắp xếp theo',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final isSelected = current == opt.$1;
            return GestureDetector(
              onTap: () => onSelect(opt.$1),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF006E2F).withValues(alpha: 0.06)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF006E2F).withValues(alpha: 0.2)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF006E2F).withValues(alpha: 0.1)
                            : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(opt.$2, size: 18,
                          color: isSelected ? const Color(0xFF006E2F) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 14),
                    Text(opt.$3,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF006E2F) : const Color(0xFF334155))),
                    const Spacer(),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF006E2F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Skeleton Loading
// ─────────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bar(100, 16),
                _bar(60, 20),
              ],
            ),
            const SizedBox(height: 6),
            _bar(150, 12),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _bar(80, 36), // Plate skeleton
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(120, 14),
                        const SizedBox(height: 6),
                        _bar(60, 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _bar(100, 28)),
                const SizedBox(width: 12),
                Expanded(child: _bar(100, 28)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bar(120, 12),
                _bar(80, 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(double width, double height) => Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: Color.fromRGBO(226, 232, 240, _anim.value),
          borderRadius: BorderRadius.circular(8),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Status Badge - style mới có dot
// ─────────────────────────────────────────────────────────────

class _StatusBadgeNew extends StatelessWidget {
  final String status;
  const _StatusBadgeNew({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTab {
  final String label;
  final String? status;
  const _StatusTab(this.label, this.status);
}

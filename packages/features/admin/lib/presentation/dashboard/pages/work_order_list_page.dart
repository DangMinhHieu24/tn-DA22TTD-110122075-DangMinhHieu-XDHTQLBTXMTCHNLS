import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'work_order_detail_page.dart';

String _safeFormatDate(String? raw, {String fallback = ''}) {
  if (raw == null) return fallback;
  try {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(raw));
  } catch (_) {
    return raw;
  }
}

String _formatCurrency(num? amount) {
  if (amount == null || amount == 0) return '';
  return NumberFormat.compactCurrency(
      locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
      .format(amount);
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

Color _priorityColor(String priority) => switch (priority) {
      'URGENT' => const Color(0xFFBA1A1A),
      'HIGH' => const Color(0xFFB45309),
      'NORMAL' => const Color(0xFF006E2F),
      _ => const Color(0xFF9CA3AF),
    };

class WorkOrderListPage extends StatefulWidget {
  const WorkOrderListPage({super.key});

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
    _tabController = TabController(length: _tabs.length, vsync: this);
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
      final response = await dio.get(
        '/work-orders',
        queryParameters: status != null ? {'status': status} : null,
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

    final priorityOrder = {'URGENT': 0, 'HIGH': 1, 'NORMAL': 2, 'LOW': 3};
    switch (_sortBy) {
      case 'newest':
        list.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
      case 'oldest':
        list.sort((a, b) => (a['createdAt'] ?? '').compareTo(b['createdAt'] ?? ''));
      case 'priority':
        list.sort((a, b) {
          final pa = priorityOrder[a['priority']] ?? 2;
          final pb = priorityOrder[b['priority']] ?? 2;
          return pa.compareTo(pb);
        });
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
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phiếu Sửa Chữa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${_workOrders.length} phiếu',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF006E2F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // Search field
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                decoration: InputDecoration(
                  hintText: 'Tìm biển số, mã phiếu, tên KH...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.cancel, color: Color(0xFF9CA3AF), size: 16),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  isDense: true,
                ),
              ),
            ),
            // Divider
            Container(width: 1, height: 22, color: const Color(0xFFD1D5DB)),
            // Bộ lọc button
            GestureDetector(
              onTap: _showSortSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: _sortBy != 'newest'
                          ? const Color(0xFF006E2F)
                          : const Color(0xFF374151),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _sortBy == 'priority'
                          ? 'Ưu tiên'
                          : _sortBy == 'oldest'
                              ? 'Cũ nhất'
                              : 'Bộ lọc',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _sortBy != 'newest'
                            ? const Color(0xFF006E2F)
                            : const Color(0xFF374151),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF006E2F) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.value.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF6B7280),
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.3)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF374151),
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
            child: Text('Xác nhận'),
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
    final priority = (data['priority'] ?? 'NORMAL') as String;
    final orderNumber = data['orderNumber'] ?? '';
    final plate = data['vehicle']?['licensePlate'] ?? 'N/A';
    final vehicleModel = data['vehicle']?['vehicleModel'] ?? data['vehicle']?['model'] ?? '';
    final ownerName = data['vehicle']?['owner']?['name'] ?? 'N/A';
    final techName = data['technician']?['name'] ?? 'Chưa phân công';
    final createdAt = _safeFormatDate(data['createdAt'] as String?);
    final services = (data['services'] as List<dynamic>? ?? []);
    final serviceText = services
        .map((s) => s['serviceType'] ?? '')
        .where((s) => s.isNotEmpty)
        .join(' · ');

    final canConfirm = status == 'PENDING' || status == 'IN_PROGRESS';
    final nextLabel = status == 'PENDING' ? 'Bắt đầu' : 'Hoàn tất';
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: nextColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == 'PENDING' ? Icons.play_arrow_rounded : Icons.check_circle_rounded,
              color: Colors.white, size: 28,
            ),
            const SizedBox(height: 4),
            Text(nextLabel,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ── Priority bar bên trái - theo màu STATUS ──
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                // ── Nội dung ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111827),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (serviceText.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      serviceText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B7280),
                                        letterSpacing: 0.3,
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

                        // Row 2: Vehicle box - theo màu STATUS
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Icon xe tròn - theo màu STATUS
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.electric_moped,
                                    size: 22, color: _statusColor(status)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plate,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                    if (vehicleModel.isNotEmpty)
                                      Text(
                                        vehicleModel,
                                        style: const TextStyle(
                                            fontSize: 13, color: Color(0xFF6B7280)),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Row 3: Khách hàng | Kỹ thuật viên (2 cột)
                        Row(
                          children: [
                            // Cột trái: Khách hàng
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'KHÁCH HÀNG',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF9CA3AF),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          size: 14, color: Color(0xFF374151)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ownerName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Cột phải: KTV
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'KỸ THUẬT VIÊN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF9CA3AF),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.build_outlined,
                                          size: 14, color: Color(0xFF0058BE)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          techName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0058BE),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Divider
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 10),

                        // Row 4: Thời gian + Chi tiết
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 13, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(
                              createdAt,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9CA3AF)),
                            ),
                            const Spacer(),
                            if (canConfirm)
                              Text(
                                'Vuốt để $nextLabel',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: nextColor.withValues(alpha: 0.6)),
                              )
                            else
                              Row(
                                children: [
                                  Text(
                                    'Chi tiết',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF006E2F),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 18, color: Color(0xFF006E2F)),
                                ],
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
      ('priority', Icons.flag_rounded, 'Theo mức ưu tiên'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Sắp xếp theo',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final isSelected = current == opt.$1;
            return GestureDetector(
              onTap: () => onSelect(opt.$1),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF006E2F).withValues(alpha: 0.08)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF006E2F).withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(opt.$2, size: 18,
                        color: isSelected ? const Color(0xFF006E2F) : const Color(0xFF6B7280)),
                    const SizedBox(width: 12),
                    Text(opt.$3,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? const Color(0xFF006E2F) : const Color(0xFF374151))),
                    const Spacer(),
                    if (isSelected)
                      const Icon(Icons.check_rounded, size: 18, color: Color(0xFF006E2F)),
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
    _anim = Tween<double>(begin: 0.4, end: 0.9)
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(120, 14),
            const SizedBox(height: 12),
            _bar(80, 10),
            const SizedBox(height: 8),
            _bar(160, 10),
            const SizedBox(height: 8),
            _bar(100, 10),
          ],
        ),
      ),
    );
  }

  Widget _bar(double width, double height) => Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: Color.fromRGBO(200, 200, 200, _anim.value),
          borderRadius: BorderRadius.circular(6),
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
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Status Badge (cũ - giữ lại)
// ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: color, letterSpacing: 0.1)),
    );
  }
}

class _StatusTab {
  final String label;
  final String? status;
  const _StatusTab(this.label, this.status);
}

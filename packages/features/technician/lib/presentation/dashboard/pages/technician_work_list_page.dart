import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import '../../../domain/entities/work_item.dart';
import '../../work_detail/pages/work_detail_page.dart';
import '../widgets/work_card.dart';

class TechnicianWorkListPage extends StatefulWidget {
  final List<WorkItem> workItems;

  const TechnicianWorkListPage({super.key, required this.workItems});

  @override
  State<TechnicianWorkListPage> createState() => _TechnicianWorkListPageState();
}

class _TechnicianWorkListPageState extends State<TechnicianWorkListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeItems = widget.workItems
        .where((item) => item.status != WorkStatus.completed && item.status != WorkStatus.cancelled)
        .toList();
    final cancelledItems = widget.workItems
        .where((item) => item.status == WorkStatus.cancelled)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Danh sách công việc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF191C1E),
        elevation: 0,
        scrolledUnderElevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF006E2F),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF006E2F),
          tabs: [
            Tab(text: 'Đang thực hiện (${activeItems.length})'),
            Tab(text: 'Đã hủy (${cancelledItems.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(activeItems, 'Không có công việc nào'),
          _buildList(cancelledItems, 'Không có đơn bị hủy'),
        ],
      ),
    );
  }

  Widget _buildList(List<WorkItem> items, String emptyText) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: Color(0xFFBCCBB9)),
            const SizedBox(height: 16),
            Text(emptyText, style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return WorkCard(
          licensePlate: item.licensePlate,
          vehicleModel: item.vehicleModel,
          customerName: item.customerName,
          description: item.description,
          time: item.scheduledTime,
          status: _statusLabel(item.status),
          statusColor: _statusColor(item.status),
          isInProgress: item.status == WorkStatus.inProgress,
          onDetailTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkDetailPage(workItem: item)),
          ),
        );
      },
    );
  }

  Color _statusColor(WorkStatus status) => switch (status) {
    WorkStatus.pending => const Color(0xFFB45309),
    WorkStatus.inProgress => const Color(0xFF0058BE),
    WorkStatus.inspection => const Color(0xFF6D28D9),
    WorkStatus.completed => const Color(0xFF006E2F),
    WorkStatus.cancelled => const Color(0xFFBA1A1A),
  };

  String _statusLabel(WorkStatus status) => switch (status) {
    WorkStatus.pending => 'Chờ xử lý',
    WorkStatus.inProgress => 'Đang làm',
    WorkStatus.inspection => 'Kiểm tra',
    WorkStatus.completed => 'Hoàn tất',
    WorkStatus.cancelled => 'Đã hủy',
  };
}

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import '../../../domain/entities/work_item.dart';
import '../../../domain/usecases/get_work_items_usecase.dart';

class TechStatsPage extends StatefulWidget {
  const TechStatsPage({super.key});

  @override
  State<TechStatsPage> createState() => _TechStatsPageState();
}

class _TechStatsPageState extends State<TechStatsPage> {
  List<WorkItem>? _items;
  bool _loading = true;
  String? _error;
  String _userName = 'Kỹ thuật viên';

  static const _kGreen = Color(0xFF006E2F);
  static const _kBg = Color(0xFFF8FAFB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final authState = GetIt.instance<AuthBloc>().state;
      String? userId;
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
        _userName = authState.user.name ?? 'Kỹ thuật viên';
      }
      final useCase = GetIt.instance<GetWorkItemsUseCase>();
      final result = await useCase(GetWorkItemsParams(technicianId: userId));
      await result.fold(
        (failure) async => setState(() {
          _error = 'Không thể tải dữ liệu';
          _loading = false;
        }),
        (items) async => setState(() {
          _items = items;
          _loading = false;
        }),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
            Icon(Icons.bar_chart_rounded, size: 18, color: _kGreen),
            SizedBox(width: 10),
            Text(
              'Thống kê',
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
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(_kGreen)),
            )
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: Color(0xFFDC2626)),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final items = _items!;

    final total = items.length;
    final completed =
        items.where((i) => i.status == WorkStatus.completed).length;
    final inProgress =
        items.where((i) => i.status == WorkStatus.inProgress).length;
    final cancelled =
        items.where((i) => i.status == WorkStatus.cancelled).length;
    final pending =
        items.where((i) => i.status == WorkStatus.pending).length;

    final revenue = items
        .where((i) => i.status == WorkStatus.completed)
        .fold<double>(0, (sum, i) {
      return sum +
          i.services.fold<double>(0, (s, sv) => s + (sv.price ?? 0));
    });

    final recentItems = items
        .where((i) => i.status == WorkStatus.completed)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildStatRow(total, completed, inProgress, cancelled, pending),
        const SizedBox(height: 20),
        _buildRevenueCard(revenue),
        const SizedBox(height: 20),
        if (recentItems.isNotEmpty) ...[
          _buildSectionTitle('Phiếu đã hoàn thành gần đây'),
          const SizedBox(height: 10),
          ...recentItems.take(5).map(_buildRecentItem),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF006E2F), Color(0xFF059669)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'K',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Kỹ thuật viên',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(int total, int completed, int inProgress,
      int cancelled, int pending) {
    return Row(
      children: [
        _buildStatCard('Tổng việc', '$total', _kGreen, Icons.work_history),
        const SizedBox(width: 10),
        _buildStatCard('Hoàn tất', '$completed', const Color(0xFF16A34A),
            Icons.check_circle_outline),
        const SizedBox(width: 10),
        _buildStatCard(
            'Đang làm', '$inProgress', const Color(0xFF0058BE), Icons.build),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(double revenue) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006E2F), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.monetization_on_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng doanh thu',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                '${revenue.toStringAsFixed(0)}đ',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF191C1E),
      ),
    );
  }

  Widget _buildRecentItem(WorkItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle, color: _kGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.licensePlate,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _kGreen)),
                const SizedBox(height: 2),
                Text(item.customerName,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF191C1E))),
              ],
            ),
          ),
          Text(
            _formatDate(item.createdAt),
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}

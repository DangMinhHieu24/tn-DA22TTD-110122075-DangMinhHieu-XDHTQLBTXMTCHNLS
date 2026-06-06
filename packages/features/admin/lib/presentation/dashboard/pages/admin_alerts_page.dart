import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/dashboard_stats.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class AdminAlertsPage extends StatelessWidget {
  const AdminAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_outlined, size: 22, color: Color(0xFF006E2F)),
            SizedBox(width: 8),
            Text(
              'Cảnh báo hệ thống',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF006E2F)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF7F9FB).withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFDAE4DC).withValues(alpha: 0.5)),
        ),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const _LoadingState();
          }
          if (state is DashboardError) {
            return _ErrorState(message: state.message);
          }
          if (state is DashboardLoaded) {
            return _AlertsBody(alerts: state.stats.alerts);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _AlertsBody extends StatelessWidget {
  final List<SystemAlert> alerts;

  const _AlertsBody({required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const _EmptyState();
    }

    final grouped = <AlertType, List<SystemAlert>>{};
    for (final a in alerts) {
      grouped.putIfAbsent(a.type, () => []).add(a);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _buildSummaryChips(grouped),
        const SizedBox(height: 24),
        ..._buildGroupedSections(grouped),
      ],
    );
  }

  static const _alertMeta = {
    AlertType.lowStock: (
      icon: Icons.inventory_2_outlined,
      label: 'Phụ tùng sắp hết',
      color: Color(0xFFBA1A1A),
      bgColor: Color(0xFFFFDAD6),
    ),
    AlertType.delayedVehicle: (
      icon: Icons.schedule_outlined,
      label: 'Xe trễ hẹn',
      color: Color(0xFF9E4036),
      bgColor: Color(0xFFFFE5E1),
    ),
    AlertType.warrantyExpiring: (
      icon: Icons.shield_outlined,
      label: 'Bảo hành sắp hết hạn',
      color: Color(0xFF6D7B6C),
      bgColor: Color(0xFFF2F4F6),
    ),
    AlertType.partWarrantyExpiring: (
      icon: Icons.build_outlined,
      label: 'Bảo hành linh kiện sắp hết',
      color: Color(0xFF9E4036),
      bgColor: Color(0xFFFFE5E1),
    ),
  };

  Widget _buildSummaryChips(Map<AlertType, List<SystemAlert>> grouped) {
    if (grouped.isEmpty) return const SizedBox.shrink();
    final chips = grouped.entries.map((e) {
      final meta = _alertMeta[e.key]!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: meta.bgColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: meta.color.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(meta.icon, size: 14, color: meta.color),
            const SizedBox(width: 6),
            Text(
              '${e.value.length} ${meta.label.toLowerCase()}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: meta.color),
            ),
          ],
        ),
      );
    }).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  List<Widget> _buildGroupedSections(Map<AlertType, List<SystemAlert>> grouped) {
    final order = [AlertType.lowStock, AlertType.delayedVehicle, AlertType.warrantyExpiring, AlertType.partWarrantyExpiring];
    final sections = <Widget>[];

    for (final type in order) {
      final items = grouped[type];
      if (items == null || items.isEmpty) continue;
      final meta = _alertMeta[type]!;

      sections.add(_buildSectionHeader(meta.icon, meta.label, meta.color));
      sections.add(const SizedBox(height: 12));
      for (final alert in items) {
        sections.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildAlertCard(alert, meta),
        ));
      }
      sections.add(const SizedBox(height: 8));
    }

    return sections;
  }

  Widget _buildSectionHeader(IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(SystemAlert alert, dynamic meta) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: meta.bgColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meta.color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: meta.color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meta.icon, color: meta.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: const TextStyle(
                    fontSize: 12, color: Color(0xFF4F5B50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(4, (_) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120, height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200, height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF006E2F).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, size: 40, color: Color(0xFF006E2F)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Không có cảnh báo nào',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF191C1E)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hệ thống đang hoạt động ổn định',
            style: TextStyle(fontSize: 14, color: Color(0xFF5E6B5F)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 36, color: Color(0xFFBA1A1A)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không thể tải cảnh báo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF191C1E)),
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF5E6B5F))),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<DashboardBloc>().add(LoadDashboardStats()),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF006E2F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

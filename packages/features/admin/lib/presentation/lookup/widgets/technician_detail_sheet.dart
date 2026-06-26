import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/lookup_result.dart';
import '../../../data/datasources/remote/lookup_remote_datasource.dart';

class TechnicianDetailSheet extends StatefulWidget {
  final TechnicianLookupResult technician;
  final LookupRemoteDataSource dataSource;
  final VoidCallback onUpdated;

  const TechnicianDetailSheet({
    super.key,
    required this.technician,
    required this.dataSource,
    required this.onUpdated,
  });

  static void show(BuildContext context, TechnicianLookupResult technician,
      LookupRemoteDataSource dataSource, VoidCallback onUpdated) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TechnicianDetailSheet(
        technician: technician,
        dataSource: dataSource,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<TechnicianDetailSheet> createState() => _TechnicianDetailSheetState();
}

class _TechnicianDetailSheetState extends State<TechnicianDetailSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final t = widget.technician;
    _nameCtrl = TextEditingController(text: t.name);
    _phoneCtrl = TextEditingController(text: t.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await widget.dataSource.updateUser(widget.technician.id, {
        'name': _nameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: const Color(0xFFBA1A1A)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final t = widget.technician;

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.80,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 0),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1A237E),
                        Color(0xFF283593),
                        Color(0xFF3949AB),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Avatar + info
                      Row(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                _initials(t.name),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: t.isOnline
                                            ? const Color(0xFF66BB6A)
                                            : const Color(0xFFFFCA28),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      t.isOnline ? 'Đang làm' : 'Rảnh',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Edit button
                          GestureDetector(
                            onTap: () => setState(() => _isEditing = !_isEditing),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isEditing
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isEditing ? Icons.close : Icons.edit_outlined,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _statItem(Icons.engineering, '${t.activeJobCount}', 'Việc đang làm'),
                            _statDivider(),
                            _statItem(Icons.phone_outlined, t.phoneNumber ?? '—', 'Số điện thoại'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 0),
                    ],
                  ),
                ),

                // ── Body ──
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin nhân viên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildInfoField(
                        icon: Icons.person_outline,
                        label: 'Họ và tên',
                        controller: _nameCtrl,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 14),

                      _buildInfoField(
                        icon: Icons.phone_outlined,
                        label: 'Số điện thoại',
                        controller: _phoneCtrl,
                        enabled: _isEditing,
                        digitsOnly: true,
                      ),
                      const SizedBox(height: 14),

                       _buildStatusCard(t.isOnline, t.activeJobCount),
                      const SizedBox(height: 24),
                      const Text(
                        'Hiệu suất làm việc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPerformanceCard(
                              title: 'Tháng này',
                              completedCount: t.thisMonthCompletedCount,
                              revenue: t.thisMonthRevenue,
                              isCurrentMonth: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPerformanceCard(
                              title: 'Tháng trước',
                              completedCount: t.lastMonthCompletedCount,
                              revenue: t.lastMonthRevenue,
                              isCurrentMonth: false,
                            ),
                          ),
                        ],
                      ),

                      if (_isEditing) ...[
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF283593),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Lưu thay đổi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool enabled = false,
    bool digitsOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF7986CB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A9A89),
                    ),
                  ),
                ),
                enabled
                    ? TextFormField(
                        controller: controller,
                        inputFormatters: digitsOnly
                            ? [FilteringTextInputFormatter.digitsOnly]
                            : null,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF191C1E),
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          controller.text.isEmpty ? '—' : controller.text,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isOnline, int activeJobs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFFE8F5E9).withValues(alpha: 0.5)
            : const Color(0xFFFFF8E1).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF66BB6A).withValues(alpha: 0.3)
              : const Color(0xFFFFCA28).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF66BB6A).withValues(alpha: 0.15)
                  : const Color(0xFFFFCA28).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOnline ? Icons.check_circle_outline : Icons.access_time,
              size: 20,
              color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFFF57F17),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Đang có việc' : 'Đang rảnh',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'Đang xử lý $activeJobs việc'
                      : 'Chưa nhận việc nào',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard({
    required String title,
    required int completedCount,
    required num revenue,
    required bool isCurrentMonth,
  }) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final formattedRevenue = currencyFormatter.format(revenue);

    final mainColor = isCurrentMonth ? const Color(0xFF1A237E) : const Color(0xFF455A64);
    final bgColor = isCurrentMonth
        ? const Color(0xFFE8EAF6).withValues(alpha: 0.6)
        : const Color(0xFFECEFF1).withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mainColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCurrentMonth ? Icons.trending_up : Icons.history,
                size: 16,
                color: mainColor,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: mainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$completedCount việc',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 16, color: Color(0xFFE65100)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  formattedRevenue,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF191C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

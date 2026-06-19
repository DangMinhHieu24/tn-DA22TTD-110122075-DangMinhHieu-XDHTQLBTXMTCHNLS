import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/lookup_result.dart';
import '../../../data/datasources/remote/lookup_remote_datasource.dart';

class CustomerDetailSheet extends StatefulWidget {
  final CustomerLookupResult customer;
  final LookupRemoteDataSource dataSource;
  final VoidCallback onUpdated;

  const CustomerDetailSheet({
    super.key,
    required this.customer,
    required this.dataSource,
    required this.onUpdated,
  });

  static void show(BuildContext context, CustomerLookupResult customer,
      LookupRemoteDataSource dataSource, VoidCallback onUpdated) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerDetailSheet(
        customer: customer,
        dataSource: dataSource,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<CustomerDetailSheet> createState() => _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends State<CustomerDetailSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c.name);
    _phoneCtrl = TextEditingController(text: c.phoneNumber ?? '');
    _emailCtrl = TextEditingController(text: c.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await widget.dataSource.updateUser(widget.customer.id, {
        'name': _nameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
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

  String _formatDate(DateTime d) {
    final months = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    return 'Thg ${months[d.month - 1]}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final c = widget.customer;

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Gradient header ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 0),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D3B0F),
                        Color(0xFF1B5E20),
                        Color(0xFF2E7D32),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
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

                      // Avatar + edit
                      Row(
                        children: [
                          // Avatar
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
                                _initials(c.name),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Name + phone
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (c.phoneNumber != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    c.phoneNumber!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
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

                      // ── Stats grid 2x2 ──
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _statItem(Icons.forest, '${c.treesPlanted}', 'Cây xanh'),
                                _statDivider(),
                                _statItem(Icons.card_giftcard, '${c.loyaltyPoints}', 'Điểm thưởng'),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Divider(height: 20, color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            Row(
                              children: [
                                _statItem(Icons.two_wheeler, '${c.vehicleCount}', 'Xe'),
                                _statDivider(),
                                _statItem(Icons.calendar_today, _formatDate(c.createdAt), 'Thành viên'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 0),
                    ],
                  ),
                ),

                // ── Body section ──
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin liên hệ',
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

                      _buildInfoField(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        controller: _emailCtrl,
                        enabled: _isEditing,
                      ),

                      if (_isEditing) ...[
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
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
          Icon(icon, size: 20, color: const Color(0xFF6D7B6C)),
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
}

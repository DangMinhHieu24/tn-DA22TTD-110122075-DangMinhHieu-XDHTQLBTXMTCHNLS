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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48, height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBDEE0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chi tiết khách hàng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF191C1E)),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isEditing = !_isEditing),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isEditing ? const Color(0xFF006E2F) : const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEditing ? Icons.close : Icons.edit_outlined,
                      size: 20,
                      color: _isEditing ? Colors.white : const Color(0xFF006E2F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.person_outline, 'Tên', _nameCtrl, enabled: _isEditing),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', _phoneCtrl, enabled: _isEditing),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, 'Email', _emailCtrl, enabled: _isEditing),
            const SizedBox(height: 12),
            _buildStaticRow('Số xe', '${widget.customer.vehicleCount}'),
            const SizedBox(height: 8),
            _buildStaticRow('Điểm loyalty', '${widget.customer.loyaltyPoints}'),
            const SizedBox(height: 8),
            _buildStaticRow('Ngày tạo', widget.customer.createdAt.toLocal().toString().split('.')[0]),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006E2F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, TextEditingController ctrl, {bool enabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6D7B6C))),
        const SizedBox(height: 4),
        enabled
            ? TextFormField(
                controller: ctrl,
                inputFormatters: label == 'Số điện thoại'
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF191C1E)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF7F9FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDBDEE0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDBDEE0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF006E2F), width: 1.5),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ctrl.text.isEmpty ? '—' : ctrl.text,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF191C1E)),
                ),
              ),
      ],
    );
  }

  Widget _buildStaticRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6D7B6C))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF191C1E))),
      ],
    );
  }
}
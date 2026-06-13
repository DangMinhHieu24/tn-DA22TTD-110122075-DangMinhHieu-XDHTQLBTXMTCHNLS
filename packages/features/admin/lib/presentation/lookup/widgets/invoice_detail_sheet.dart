import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/entities/lookup_result.dart';

class InvoiceDetailSheet extends StatefulWidget {
  final InvoiceLookupResult invoice;

  const InvoiceDetailSheet({super.key, required this.invoice});

  static Future<bool?> show(BuildContext context, InvoiceLookupResult invoice) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InvoiceDetailSheet(invoice: invoice),
    );
  }

  @override
  State<InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<InvoiceDetailSheet> {
  String _selectedMethod = 'CASH';
  bool _isUpdating = false;
  late InvoiceLookupResult _invoice;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }

  Future<void> _confirmPayment() async {
    setState(() => _isUpdating = true);
    try {
      final dio = GetIt.instance<Dio>();
      await dio.patch(
        '/work-orders/${_invoice.id}/payment',
        data: {'paymentMethod': _selectedMethod},
      );
      if (!mounted) return;
      setState(() {
        _invoice = InvoiceLookupResult(
          id: _invoice.id,
          categoryId: 'invoice',
          orderNumber: _invoice.orderNumber,
          status: 'PAID',
          totalPrice: _invoice.totalPrice,
          paymentMethod: _selectedMethod,
          paidAt: DateTime.now(),
          completedAt: _invoice.completedAt,
          createdAt: _invoice.createdAt,
          notes: _invoice.notes,
          vehicleId: _invoice.vehicleId,
          licensePlate: _invoice.licensePlate,
          vehicleBrand: _invoice.vehicleBrand,
          vehicleModel: _invoice.vehicleModel,
          customerName: _invoice.customerName,
          customerPhone: _invoice.customerPhone,
          technicianName: _invoice.technicianName,
          services: _invoice.services,
          partsUsed: _invoice.partsUsed,
        );
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xác nhận thanh toán thành công'),
          backgroundColor: const Color(0xFF006E2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = _invoice;
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(inv.orderNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF191C1E))),
                _statusBadge(inv),
              ],
            ),
            const SizedBox(height: 20),

            // Customer & vehicle info
            _section('Khách hàng', [
              _infoRow(Icons.person_outline, inv.customerName ?? '—'),
              _infoRow(Icons.phone_outlined, inv.customerPhone ?? '—'),
            ]),
            const SizedBox(height: 16),
            _section('Xe', [
              _infoRow(Icons.two_wheeler_outlined, inv.licensePlate ?? '—'),
              if (inv.vehicleBrand != null || inv.vehicleModel != null)
                _infoRow(Icons.build_outlined, '${inv.vehicleBrand ?? ''} ${inv.vehicleModel ?? ''}'.trim()),
            ]),

            if (inv.technicianName != null) ...[
              const SizedBox(height: 16),
              _section('Kỹ thuật viên', [
                _infoRow(Icons.engineering_outlined, inv.technicianName!),
              ]),
            ],

            // Services
            if (inv.services.isNotEmpty) ...[
              const SizedBox(height: 16),
              _section('Dịch vụ đã thực hiện', inv.services.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF006E2F)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.serviceName ?? s.description ?? s.serviceType, style: const TextStyle(fontSize: 13, color: Color(0xFF3D4A3D)))),
                    if (s.price != null)
                      Text(_formatCurrency(s.price!), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF191C1E))),
                  ],
                ),
              )).toList()),
            ],

            // Parts
            if (inv.partsUsed.isNotEmpty) ...[
              const SizedBox(height: 16),
              _section('Phụ tùng', inv.partsUsed.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.build_outlined, size: 16, color: Color(0xFF455A64)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${p.partName} x${p.quantity}', style: const TextStyle(fontSize: 13, color: Color(0xFF3D4A3D)))),
                    Text(_formatCurrency(p.unitPrice * p.quantity), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF191C1E))),
                  ],
                ),
              )).toList()),
            ],

            // Payment info
            const SizedBox(height: 16),
            _section('Thanh toán', [
              if (inv.paymentMethod != null)
                _infoRow(Icons.payment_outlined, _paymentLabel(inv.paymentMethod!)),
              if (inv.paidAt != null)
                _infoRow(Icons.calendar_today, _formatDate(inv.paidAt!)),
            ]),

            // Payment method selection (only for unpaid invoices)
            if (!inv.isPaid) ...[
              const SizedBox(height: 16),
              const Text('Phương thức thanh toán', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6D7B6C))),
              const SizedBox(height: 8),
              Row(
                children: [
                  _paymentMethodChip('CASH', Icons.money, 'Tiền mặt'),
                  const SizedBox(width: 8),
                  _paymentMethodChip('CARD', Icons.credit_card, 'Thẻ'),
                  const SizedBox(width: 8),
                  _paymentMethodChip('TRANSFER', Icons.account_balance, 'Chuyển khoản'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isUpdating ? null : _confirmPayment,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006E2F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isUpdating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Xác nhận đã thanh toán', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],

            // Total
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF191C1E))),
                Text(
                  inv.totalPrice != null ? _formatCurrency(inv.totalPrice!) : '—',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF006E2F)),
                ),
              ],
            ),

            if (inv.notes != null && inv.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Ghi chú', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6D7B6C))),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(inv.notes!, style: const TextStyle(fontSize: 13, color: Color(0xFF3D4A3D))),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paymentMethodChip(String method, IconData icon, String label) {
    final selected = _selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF006E2F) : const Color(0xFFF0F6F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF006E2F) : const Color(0xFFDDE7E2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? Colors.white : const Color(0xFF3D4A3D)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF3D4A3D))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(InvoiceLookupResult inv) {
    final isPaid = inv.isPaid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isPaid ? const Color(0xFF006E2F) : const Color(0xFFE65100)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isPaid ? const Color(0xFF006E2F) : const Color(0xFFE65100)),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6D7B6C))),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6D7B6C)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF3D4A3D)))),
        ],
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'CASH': return 'Tiền mặt';
      case 'CARD': return 'Thẻ ngân hàng';
      case 'TRANSFER': return 'Chuyển khoản';
      default: return method;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫';
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/lookup_result.dart';
import '../bloc/lookup_bloc.dart';
import '../bloc/lookup_event.dart';
import '../bloc/lookup_state.dart';
import '../widgets/invoice_detail_sheet.dart';

class InvoiceLookupPage extends StatefulWidget {
  const InvoiceLookupPage({super.key});

  @override
  State<InvoiceLookupPage> createState() => _InvoiceLookupPageState();
}

class _InvoiceLookupPageState extends State<InvoiceLookupPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<LookupBloc>().add(const PerformLookupSearch(categoryId: 'invoice'));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<LookupBloc>().add(PerformLookupSearch(categoryId: 'invoice', query: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF191C1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tra cứu hoá đơn',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF191C1E)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã phiếu, tên khách, SĐT, biển số...',
                hintStyle: const TextStyle(color: Color(0xFF9DA3A8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6D7B6C)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF2F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<LookupBloc, LookupState>(
        builder: (context, state) {
          if (state is LookupSearchLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LookupSearchError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Color(0xFFBA1A1A)),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: Color(0xFF6D7B6C))),
                ],
              ),
            );
          }
          if (state is LookupSearchLoaded) {
            final items = state.results.whereType<InvoiceLookupResult>().toList();
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: const Color(0xFFDBDEE0)),
                    const SizedBox(height: 16),
                    const Text('Không tìm thấy hoá đơn', style: TextStyle(fontSize: 16, color: Color(0xFF6D7B6C))),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _buildInvoiceCard(items[i]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceLookupResult inv) {
    final isPaid = inv.isPaid;
    final statusColor = isPaid ? const Color(0xFF006E2F) : const Color(0xFFE65100);
    final statusLabel = isPaid ? 'Đã thanh toán' : 'Chưa thanh toán';

    return GestureDetector(
      onTap: () async {
        final paid = await InvoiceDetailSheet.show(context, inv);
        if (paid == true && context.mounted) {
          context.read<LookupBloc>().add(const PerformLookupSearch(categoryId: 'invoice'));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(inv.orderNumber,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF191C1E))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Color(0xFF6D7B6C)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(inv.customerName ?? '—',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF3D4A3D))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.two_wheeler_outlined, size: 16, color: Color(0xFF6D7B6C)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(inv.licensePlate ?? '—',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF3D4A3D))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF6D7B6C)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(inv.customerPhone ?? '—',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF3D4A3D))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(inv.completedAt ?? inv.createdAt),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9DA3A8)),
                ),
                Text(
                  inv.totalPrice != null ? '${_formatCurrency(inv.totalPrice!)}' : '—',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF191C1E)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫';
  }
}
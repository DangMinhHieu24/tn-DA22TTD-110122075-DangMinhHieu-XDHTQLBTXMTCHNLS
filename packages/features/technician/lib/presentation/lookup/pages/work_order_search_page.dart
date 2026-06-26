import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:auth/auth.dart';
import '../../../domain/entities/work_item.dart';
import '../../work_detail/pages/work_detail_page.dart';
import '../bloc/work_order_search_bloc.dart';

class WorkOrderSearchPage extends StatefulWidget {
  const WorkOrderSearchPage({super.key});

  @override
  State<WorkOrderSearchPage> createState() => _WorkOrderSearchPageState();
}

class _WorkOrderSearchPageState extends State<WorkOrderSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isSearchFocused = false;
  bool _initialLoaded = false;
  String? _technicianId;

  static const _kGreen = Color(0xFF006E2F);
  static const _kBg = Color(0xFFF8FAFB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialLoaded) {
        _initialLoaded = true;
        final authState = GetIt.instance<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          _technicianId = authState.user.id;
        }
        context.read<WorkOrderSearchBloc>().add(
          LoadWorkOrders(technicianId: _technicianId),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context
          .read<WorkOrderSearchBloc>()
          .add(SearchWorkOrders(value.trim(), technicianId: _technicianId));
    });
  }

  void _openWorkDetail(WorkItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkDetailPage(workItem: item),
      ),
    );
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
            Icon(Icons.receipt_long_rounded, size: 18, color: _kGreen),
            SizedBox(width: 10),
            Text(
              'Phiếu sửa chữa',
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
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSearchFocused ? _kGreen : const Color(0xFFE5E7EB),
          width: _isSearchFocused ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSearchFocused
                ? _kGreen.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: _isSearchFocused ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search_rounded,
            color: _isSearchFocused ? _kGreen : const Color(0xFF9CA3AF),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode..addListener(() {
                setState(() => _isSearchFocused = _focusNode.hasFocus);
              }),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191C1E),
              ),
              decoration: const InputDecoration(
                hintText: 'Biển số, tên khách hàng...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _searchController,
            builder: (_, value, __) {
              if (value.text.isNotEmpty) {
                return IconButton(
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<WorkOrderSearchBloc>()
                        .add(const LoadWorkOrders());
                  },
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF6D7B6C), size: 20),
                );
              }
              return const SizedBox(width: 8);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<WorkOrderSearchBloc, WorkOrderSearchState>(
      builder: (context, state) {
        if (state is WorkOrderSearchInitial ||
            state is WorkOrderSearchLoading) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_kGreen),
            ),
          );
        }
        if (state is WorkOrderSearchError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Color(0xFFDC2626)),
                const SizedBox(height: 16),
                Text(state.message,
                    style: const TextStyle(color: Color(0xFF6B7280))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<WorkOrderSearchBloc>().add(
                            const LoadWorkOrders(),
                          ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        if (state is WorkOrderSearchLoaded) {
          final orders = state.workOrders;
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        size: 40, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Không có phiếu sửa chữa nào',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final q = state.query;
              context.read<WorkOrderSearchBloc>().add(
                    q != null && q.isNotEmpty
                        ? SearchWorkOrders(q, technicianId: _technicianId)
                        : LoadWorkOrders(technicianId: _technicianId),
                  );
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: orders.length,
              itemBuilder: (context, index) =>
                  _buildWorkCard(orders[index]),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWorkCard(WorkItem item) {
    final statusText = _statusLabel(item.status);
    final statusColor = _statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openWorkDetail(item),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.licensePlate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _kGreen,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.customerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'WO-${item.id.length > 8 ? item.id.substring(0, 8).toUpperCase() : item.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(WorkStatus status) => switch (status) {
    WorkStatus.pending => 'Chờ xử lý',
    WorkStatus.inProgress => 'Đang làm',
    WorkStatus.inspection => 'Kiểm tra',
    WorkStatus.completed => 'Hoàn tất',
    WorkStatus.cancelled => 'Đã hủy',
  };

  Color _statusColor(WorkStatus status) => switch (status) {
    WorkStatus.pending => const Color(0xFFB45309),
    WorkStatus.inProgress => const Color(0xFF0058BE),
    WorkStatus.inspection => const Color(0xFF6D28D9),
    WorkStatus.completed => const Color(0xFF006E2F),
    WorkStatus.cancelled => const Color(0xFFBA1A1A),
  };
}

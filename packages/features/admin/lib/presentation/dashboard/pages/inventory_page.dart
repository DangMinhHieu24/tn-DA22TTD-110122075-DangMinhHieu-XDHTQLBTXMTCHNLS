import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';
import '../widgets/inventory_item_card.dart';
import '../widgets/inventory_form_sheet.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late final InventoryBloc _bloc;
  final _searchCtrl = TextEditingController();
  int _selectedFilterIndex = 0;

  // Category filter chips — mô phỏng UI design, filter theo tên nếu cần
  final List<String> _filterLabels = [
    'Tất cả',
    'Pin & Điện',
    'Má phanh',
    'Lốp xe',
    'Động cơ',
  ];

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<InventoryBloc>();
    _bloc.add(const LoadInventory());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildFilterChips(),
              Expanded(
                child: BlocConsumer<InventoryBloc, InventoryState>(
                  listener: (context, state) {
                    if (state is InventoryError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: const Color(0xFFBA1A1A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                      _bloc.add(const LoadInventory());
                    }
                  },
                  builder: (context, state) {
                    if (state is InventoryLoading || state is InventoryInitial) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF006E2F)),
                      );
                    }

                    if (state is InventoryLoaded || state is InventorySubmitting) {
                      final loaded = state is InventoryLoaded
                          ? state
                          : (_bloc.state is InventoryLoaded
                              ? _bloc.state as InventoryLoaded
                              : null);

                      if (loaded == null) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF006E2F)),
                        );
                      }

                      return _buildList(context, loaded);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: BlocBuilder<InventoryBloc, InventoryState>(
          builder: (context, _) => _buildFAB(context),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      // Glass effect header
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB).withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // AppBar row: back + title (centered) + empty
          SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xFF006E2F),
                      iconSize: 22,
                    ),
                  ),
                  const Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Kho phụ tùng',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF006E2F),
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E3E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (q) => _bloc.add(SearchInventory(q)),
                style: const TextStyle(fontSize: 15, color: Color(0xFF191C1E)),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF6D7B6C), size: 22),
                  hintText: 'Tìm kiếm phụ tùng, mã SKU...',
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFF6D7B6C)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilterIndex = index);
              // Re-search with current query to apply filter
              _bloc.add(SearchInventory(_searchCtrl.text));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF191C1E) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF191C1E).withValues(alpha: 0.06),
                    blurRadius: selected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: selected
                    ? null
                    : Border.all(
                        color: const Color(0xFFBCCBB9).withValues(alpha: 0.15),
                      ),
              ),
              child: Text(
                _filterLabels[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : const Color(0xFF3D4A3D),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, InventoryLoaded state) {
    final items = state.filteredItems;

    if (items.isEmpty) {
      return _buildEmptyState(state.searchQuery.isNotEmpty);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Dismissible(
          key: Key(items[index].id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline_rounded, color: Color(0xFF93000A), size: 22),
                SizedBox(height: 4),
                Text(
                  'Xóa',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF93000A),
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (_) async {
            bool confirmed = false;
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('Xóa phụ tùng?',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF191C1E))),
                content: Text('Bạn có chắc muốn xóa "${items[index].partName}"?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      confirmed = false;
                      Navigator.pop(ctx);
                    },
                    child: const Text('Hủy', style: TextStyle(color: Color(0xFF3D4A3D))),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      confirmed = true;
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA1A1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Xóa', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            return confirmed;
          },
          onDismissed: (_) => _bloc.add(DeleteInventoryItem(items[index].id)),
          child: InventoryItemCard(item: items[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isSearch) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF006E2F)),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'Không tìm thấy phụ tùng' : 'Kho chưa có phụ tùng nào',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch ? 'Thử tìm với từ khóa khác' : 'Nhấn nút "+" để thêm phụ tùng đầu tiên',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6D7B6C)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006E2F), Color(0xFF22C55E)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            InventoryFormSheet.showCreate(context, (data) {
              _bloc.add(CreateInventoryItem(data));
            });
          },
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

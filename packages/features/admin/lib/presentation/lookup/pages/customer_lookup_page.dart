import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../data/datasources/remote/lookup_remote_datasource.dart';
import '../../../domain/entities/lookup_result.dart';
import '../bloc/lookup_bloc.dart';
import '../bloc/lookup_event.dart';
import '../bloc/lookup_state.dart';
import '../widgets/customer_search_result_card.dart';
import '../widgets/customer_detail_sheet.dart';
import '../widgets/technician_detail_sheet.dart';

class CustomerLookupPage extends StatefulWidget {
  const CustomerLookupPage({super.key});

  @override
  State<CustomerLookupPage> createState() => _CustomerLookupPageState();
}

class _CustomerLookupPageState extends State<CustomerLookupPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  int _selectedTab = 0; // 0 = Khách hàng, 1 = Nhân viên

  static const _kDebounceMs = 400;
  static const _kGreen = Color(0xFF006E2F);
  static const _kBg = Color(0xFFF7F9FB);
  static const _kTabs = ['Khách hàng', 'Nhân viên'];

  String get _currentCategoryId => _selectedTab == 0 ? 'customer' : 'technician';
  String get _currentHintText =>
      _selectedTab == 0 ? 'Tên, số điện thoại, email...' : 'Tên, số điện thoại...';

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _search();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _kDebounceMs), () {
      if (!mounted) return;
      _search();
    });
  }

  void _search() {
    final query = _searchController.text.trim();
    context.read<LookupBloc>().add(
          PerformLookupSearch(
            categoryId: _currentCategoryId,
            query: query.isEmpty ? null : query,
          ),
        );
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.requestFocus();
    _debounce?.cancel();
    _search();
  }

  void _switchTab(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Scaffold(
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
              Icon(Icons.people_outline, size: 20, color: _kGreen),
              SizedBox(width: 8),
              Text(
                'Tra cứu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kGreen,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildTabBar(),
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<LookupBloc, LookupState>(
                builder: (context, state) {
                  if (state is LookupInitial || state is LookupCategoriesLoaded) {
                    return _buildInitialHint();
                  }
                  if (state is LookupSearchLoading) {
                    return _buildLoading();
                  }
                  if (state is LookupSearchError) {
                    return _buildError(state.message);
                  }
                  if (state is LookupSearchLoaded) {
                    if (state.selectedCategoryId != _currentCategoryId) {
                      return _buildInitialHint();
                    }
                    if (state.results.isEmpty) {
                      return _buildEmpty();
                    }
                    return _buildResultList(state.results, state.query);
                  }
                  return _buildInitialHint();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E3E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_kTabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      i == 0 ? Icons.person_outline : Icons.build_outlined,
                      size: 16,
                      color: selected ? _kGreen : const Color(0xFF6D7B6C),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _kTabs[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? _kGreen : const Color(0xFF6D7B6C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBCCBB9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: Color(0xFF6D7B6C), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              keyboardType: TextInputType.text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191C1E),
              ),
              decoration: InputDecoration(
                hintText: _currentHintText,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _search(),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _searchController,
            builder: (_, value, __) {
              if (value.text.isNotEmpty) {
                return IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6D7B6C), size: 20),
                );
              }
              return const SizedBox(width: 8);
            },
          ),
          GestureDetector(
            onTap: _search,
            child: Container(
              margin: const EdgeInsets.all(6),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _kGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialHint() {
    final isCustomer = _selectedTab == 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isCustomer ? const Color(0xFFF3E5F5) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isCustomer ? Icons.person_outline : Icons.build_outlined,
              size: 42,
              color: isCustomer ? const Color(0xFF7B1FA2) : const Color(0xFF0058BE),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isCustomer ? 'Tìm kiếm khách hàng' : 'Tìm kiếm nhân viên',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCustomer
                ? 'Nhập tên, số điện thoại hoặc email\nđể tìm thông tin khách hàng.'
                : 'Nhập tên hoặc số điện thoại\nđể tìm thông tin nhân viên.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6D7B6C), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_kGreen),
      ),
    );
  }

  Widget _buildEmpty() {
    final isCustomer = _selectedTab == 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56,
              color: (isCustomer ? const Color(0xFF7B1FA2) : const Color(0xFF0058BE)).withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            isCustomer ? 'Không tìm thấy khách hàng nào' : 'Không tìm thấy nhân viên nào',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCustomer ? 'Thử từ khóa khác hoặc kiểm tra lại thông tin.' : 'Thử từ khóa khác.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6D7B6C)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFBA1A1A)),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải dữ liệu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF191C1E)),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF6D7B6C)),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kGreen,
              side: const BorderSide(color: _kGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList(List<LookupResult> results, String? query) {
    final isCustomer = _selectedTab == 0;
    final isDefaultList = query == null || query.trim().isEmpty;

    String headerText;
    Widget Function(int) itemBuilder;

    if (isCustomer) {
      final items = results.whereType<CustomerLookupResult>().toList();
      headerText = isDefaultList
          ? 'Khách hàng mới nhất'
          : '${items.length} kết quả cho "$query"';
      itemBuilder = (index) => CustomerSearchResultCard(
            customer: items[index],
            onTap: () {
              final ds = GetIt.instance<LookupRemoteDataSource>();
              CustomerDetailSheet.show(context, items[index], ds, () {
                _search();
              });
            },
          );
    } else {
      final items = results.whereType<TechnicianLookupResult>().toList();
      headerText = isDefaultList
          ? 'Nhân viên'
          : '${items.length} kết quả cho "$query"';
      itemBuilder = (index) => _buildTechnicianCard(items[index]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            headerText,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6D7B6C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: isCustomer
                ? results.whereType<CustomerLookupResult>().length
                : results.whereType<TechnicianLookupResult>().length,
            itemBuilder: (context, index) => itemBuilder(index),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianCard(TechnicianLookupResult tech) {
    return GestureDetector(
      onTap: () {
        final ds = GetIt.instance<LookupRemoteDataSource>();
        TechnicianDetailSheet.show(context, tech, ds, () {
          _search();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECEEF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.build_outlined, color: Color(0xFF0058BE), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tech.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF191C1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tech.isOnline
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF7D1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tech.isOnline ? 'Đang làm' : 'Rảnh',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tech.isOnline
                                ? const Color(0xFF006E2F)
                                : const Color(0xFF6B5200),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (tech.phoneNumber != null)
                    Text(
                      tech.phoneNumber!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3D4A3D),
                      ),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    '${tech.activeJobCount} việc đang làm',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6D7B6C)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBCCBB9), size: 20),
          ],
        ),
      ),
    );
  }
}
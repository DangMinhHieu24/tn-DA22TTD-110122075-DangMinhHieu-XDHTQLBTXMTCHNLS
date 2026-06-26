import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/src/theme/app_colors.dart';
import '../../../domain/entities/inventory_part.dart';
import '../bloc/parts_lookup_bloc.dart';
import '../bloc/parts_lookup_event.dart';
import '../bloc/parts_lookup_state.dart';

class PartsLookupPage extends StatefulWidget {
  const PartsLookupPage({super.key});

  @override
  State<PartsLookupPage> createState() => _PartsLookupPageState();
}

class _PartsLookupPageState extends State<PartsLookupPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isSearchFocused = false;
  bool _initialLoaded = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialLoaded) {
        _initialLoaded = true;
        context.read<PartsLookupBloc>().add(const LoadParts());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<PartsLookupBloc>().add(
            SearchParts(query: value.trim()),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.precision_manufacturing_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Kho phụ tùng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _isSearchFocused
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isSearchFocused
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.outlineVariant,
            width: _isSearchFocused ? 1.5 : 1,
          ),
          boxShadow: [
            if (_isSearchFocused)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            if (!_isSearchFocused)
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.search_rounded,
                color: _isSearchFocused
                    ? AppColors.primary
                    : AppColors.outline,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode
                  ..addListener(() =>
                      setState(() => _isSearchFocused = _focusNode.hasFocus)),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm tên phụ tùng...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.outline,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                      _focusNode.unfocus();
                      context.read<PartsLookupBloc>().add(const LoadParts());
                    },
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.outline, size: 20),
                  );
                }
                return const SizedBox(width: 8);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<PartsLookupBloc, PartsLookupState>(
      builder: (context, state) {
        if (state is PartsLookupInitial || state is PartsLookupLoading) {
          return _buildSkeletonLoading();
        }
        if (state is PartsLookupError) {
          return _buildErrorState(state.message);
        }
        if (state is PartsLookupLoaded) {
          final parts = state.parts;
          if (parts.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<PartsLookupBloc>().add(const LoadParts());
            },
            child: ListView.builder(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: parts.length,
              itemBuilder: (context, index) {
                return _buildPartCard(parts[index], index);
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      itemBuilder: (_, __) => AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(
                          alpha: 0.5 + _pulseController.value * 0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: Random().nextDouble() * 140 + 100,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh.withValues(
                                alpha: 0.5 + _pulseController.value * 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 12,
                          width: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh.withValues(
                                alpha: 0.4 + _pulseController.value * 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 44, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  context.read<PartsLookupBloc>().add(const LoadParts()),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 44, color: AppColors.outlineVariant),
          ),
          const SizedBox(height: 20),
          Text(
            'Không tìm thấy phụ tùng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử từ khóa tìm kiếm khác\nhoặc làm mới danh sách',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.outline),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              context.read<PartsLookupBloc>().add(const LoadParts());
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Làm mới'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartCard(InventoryPart part, int index) {
    final isLow = part.isLowStock;
    final isOut = part.isOutOfStock;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withValues(alpha: 0.04),
          highlightColor: AppColors.primary.withValues(alpha: 0.02),
          onTap: () => _showPartDetail(part),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOut
                    ? AppColors.error.withValues(alpha: 0.2)
                    : isLow
                        ? AppColors.tertiary.withValues(alpha: 0.2)
                        : AppColors.outlineVariant.withValues(alpha: 0.5),
                width: isLow ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildPartImage(part, isLow, isOut),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPartInfo(part, isLow, isOut)),
                  const SizedBox(width: 8),
                  _buildTrailingIndicator(part, isLow, isOut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartImage(InventoryPart part, bool isLow, bool isOut) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: part.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(15.5),
              child: Image.network(
                part.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildImagePlaceholder(isLow, isOut),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildImagePlaceholder(isLow, isOut);
                },
              ),
            )
          : _buildImagePlaceholder(isLow, isOut),
    );
  }

  Widget _buildImagePlaceholder(bool isLow, bool isOut) {
    return Container(
      decoration: BoxDecoration(
        color: isOut
            ? AppColors.errorContainer.withValues(alpha: 0.3)
            : isLow
                ? AppColors.tertiaryFixed.withValues(alpha: 0.3)
                : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(15.5),
      ),
      child: Icon(
        Icons.precision_manufacturing_outlined,
        color: isOut
            ? AppColors.error
            : isLow
                ? AppColors.tertiary
                : AppColors.outlineVariant,
        size: 28,
      ),
    );
  }

  Widget _buildPartInfo(InventoryPart part, bool isLow, bool isOut) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          part.partName,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.2,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildInfoChip(
              icon: Icons.inventory_2_rounded,
              label: '${part.quantity}',
              color: isOut
                  ? AppColors.error
                  : isLow
                      ? AppColors.tertiary
                      : AppColors.primary,
            ),
            const SizedBox(width: 10),
            Container(
              height: 14,
              width: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Text(
              _formatMoney(part.sellPrice),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailingIndicator(InventoryPart part, bool isLow, bool isOut) {
    if (isOut) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withValues(alpha: 0.12),
              AppColors.error.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          'Hết hàng',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.error,
            letterSpacing: 0.3,
          ),
        ),
      );
    }
    if (isLow) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.tertiary.withValues(alpha: 0.12),
              AppColors.tertiary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.tertiary.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          'Sắp hết',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.tertiary,
            letterSpacing: 0.3,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }

  void _showPartDetail(InventoryPart part) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.onSurface.withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (_) => _PartDetailSheet(part: part),
    );
  }

  String _formatMoney(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}đ';
  }
}

class _PartDetailSheet extends StatelessWidget {
  final InventoryPart part;
  const _PartDetailSheet({required this.part});

  @override
  Widget build(BuildContext context) {
    final isLow = part.isLowStock;
    final isOut = part.isOutOfStock;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: part.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: Image.network(part.imageUrl!,
                              fit: BoxFit.cover),
                        )
                      : Icon(Icons.precision_manufacturing_outlined,
                          size: 36, color: AppColors.outlineVariant),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.partName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusBadge(isOut ? 'Hết hàng' : isLow ? 'Sắp hết' : 'Còn hàng',
                              isOut ? AppColors.error : isLow ? AppColors.tertiary : AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Tồn: ${part.quantity}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.outline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(height: 0, color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoTile('Giá nhập', part.unitPrice),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoTile('Giá bán', part.sellPrice),
                ),
              ],
            ),
          ),
          if (part.warrantyDays != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded,
                      size: 16, color: AppColors.outline),
                  const SizedBox(width: 8),
                  Text(
                    'Bảo hành ${part.warrantyDays} ngày',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, double amount) {
    final fmt = '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}đ';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fmt,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: title == 'Giá bán' ? AppColors.primary : AppColors.onSurface,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

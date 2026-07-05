import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/entities/tech_lookup_category.dart';
import '../bloc/vehicle_detail_bloc.dart';
import '../bloc/vehicle_list_bloc.dart';
import '../bloc/parts_lookup_bloc.dart';
import 'vehicle_list_page.dart';
import 'vehicle_result_page.dart';
import 'parts_lookup_page.dart';
import '../bloc/work_order_search_bloc.dart';
import 'work_order_search_page.dart';

class TechnicianLookupPage extends StatelessWidget {
  const TechnicianLookupPage({super.key});

  static const _categories = [
    TechLookupCategory(
      id: 'vehicle',
      label: 'Danh sách xe',
      icon: Icons.directions_car,
      color: Color(0xFF006E2F),
      bgColor: Color(0xFFE8F5E9),
    ),
    TechLookupCategory(
      id: 'part',
      label: 'Tra cứu',
      icon: Icons.search_rounded,
      color: Color(0xFF7B1FA2),
      bgColor: Color(0xFFF3E5F5),
    ),
    TechLookupCategory(
      id: 'warranty',
      label: 'Bảo hành',
      icon: Icons.shield_outlined,
      color: Color(0xFF0058BE),
      bgColor: Color(0xFFE3F2FD),
    ),
    TechLookupCategory(
      id: 'work_order',
      label: 'Phiếu Sửa Chữa',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFFF7ED),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 22, color: Color(0xFF006E2F)),
            SizedBox(width: 8),
            Text(
              'Tra cứu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF006E2F),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF7F9FB).withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFDAE4DC).withValues(alpha: 0.5),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              ...List.generate((_categories.length + 1) ~/ 2, (rowIndex) {
                final start = rowIndex * 2;
                return Padding(
                  padding: EdgeInsets.only(top: rowIndex > 0 ? 24 : 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CategoryItem(
                        category: _categories[start],
                        onTap: () => _handleCategorySelected(context, _categories[start]),
                      ),
                      if (start + 1 < _categories.length)
                        const SizedBox(width: 48),
                      if (start + 1 < _categories.length)
                        _CategoryItem(
                          category: _categories[start + 1],
                          onTap: () => _handleCategorySelected(context, _categories[start + 1]),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCategorySelected(
      BuildContext context, TechLookupCategory category) {
    switch (category.id) {
      case 'vehicle':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => GetIt.instance<VehicleListBloc>(),
              child: const VehicleListPage(),
            ),
          ),
        );
      case 'part':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => GetIt.instance<PartsLookupBloc>(),
              child: const PartsLookupPage(),
            ),
          ),
        );
      case 'warranty':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => GetIt.instance<VehicleDetailBloc>(),
              child: const VehicleResultPage(initialMode: 'warranty'),
            ),
          ),
        );
      case 'work_order':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => GetIt.instance<WorkOrderSearchBloc>(),
              child: const WorkOrderSearchPage(),
            ),
          ),
        );
    }
  }
}

class _CategoryItem extends StatelessWidget {
  final TechLookupCategory category;
  final VoidCallback onTap;

  const _CategoryItem({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(category.bgColor, category.color, 0.3)!,
                  category.bgColor,
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: category.color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: category.color.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(category.icon, color: category.color, size: 28),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 90,
            child: Text(
              category.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D4A3D),
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/entities/tech_lookup_category.dart';
import '../widgets/technician_radial_menu.dart';
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
        child: TechnicianRadialMenu(
          categories: _categories,
          onCategorySelected: (category) {
            _handleCategorySelected(context, category);
          },
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

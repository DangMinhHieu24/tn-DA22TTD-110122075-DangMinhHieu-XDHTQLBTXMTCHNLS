import 'package:flutter/material.dart';
import '../../../domain/entities/lookup_category.dart';

abstract class LookupRemoteDataSource {
  Future<List<LookupCategory>> getCategories();
  // Future<List<LookupResultModel>> search(String categoryId, String? query);
}

/// A mock data source providing the default radial menu categories.
class LookupRemoteDataSourceImpl implements LookupRemoteDataSource {
  @override
  Future<List<LookupCategory>> getCategories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    return const [
      LookupCategory(
        id: 'warranty',
        label: 'Bảo hành',
        icon: Icons.shield_outlined,
        color: Color(0xFF006E2F),
        bgColor: Color(0xFFE8F5E9),
      ),
      LookupCategory(
        id: 'work_order',
        label: 'Lệnh sửa chữa',
        icon: Icons.assignment_outlined,
        color: Color(0xFF0058BE),
        bgColor: Color(0xFFE3F2FD),
      ),
      LookupCategory(
        id: 'customer',
        label: 'Khách hàng',
        icon: Icons.person_outline,
        color: Color(0xFF7B1FA2),
        bgColor: Color(0xFFF3E5F5),
      ),
      LookupCategory(
        id: 'vehicle',
        label: 'Xe',
        icon: Icons.two_wheeler,
        color: Color(0xFF455A64),
        bgColor: Color(0xFFECEFF1),
      ),
      LookupCategory(
        id: 'part',
        label: 'Phụ tùng',
        icon: Icons.build_outlined,
        color: Color(0xFFE65100),
        bgColor: Color(0xFFFFF3E0),
      ),
      LookupCategory(
        id: 'invoice',
        label: 'Hoá đơn',
        icon: Icons.receipt_long_outlined,
        color: Color(0xFF9E4036),
        bgColor: Color(0xFFFFEBEE),
      ),
    ];
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/lookup_category.dart';
import '../../../domain/entities/lookup_result.dart';
import '../../models/vehicle_model.dart';

abstract class LookupRemoteDataSource {
  Future<List<LookupCategory>> getCategories();
  Future<List<LookupResult>> search(String categoryId, String? query);
  Future<void> updateUser(String userId, Map<String, dynamic> data);
}

/// Data source cho lookup — categories từ local constant, search từ API.
class LookupRemoteDataSourceImpl implements LookupRemoteDataSource {
  final Dio dio;

  LookupRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<LookupCategory>> getCategories() async {
    // Simulate short delay (categories are static)
    await Future.delayed(const Duration(milliseconds: 200));

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

  @override
  Future<List<LookupResult>> search(String categoryId, String? query) async {
    switch (categoryId) {
      case 'vehicle':
        return _searchVehicles(query);
      case 'customer':
        return _searchCustomers(query);
      case 'technician':
        return _searchTechnicians(query);
      default:
        return [];
    }
  }

  Future<List<VehicleLookupResult>> _searchVehicles(String? query) async {
    final queryParams = <String, dynamic>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['search'] = query.trim();
    }

    final response = await dio.get(
      '/vehicles',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data
          .map((json) => _vehicleModelToResult(
                VehicleModel.fromJson(json as Map<String, dynamic>),
              ))
          .toList();
    }

    throw Exception('Tìm kiếm xe thất bại');
  }

  Future<List<CustomerLookupResult>> _searchCustomers(String? query) async {
    final queryParams = <String, dynamic>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['search'] = query.trim();
    }

    final response = await dio.get(
      '/users/customers',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data
          .map((json) => CustomerLookupResult(
                id: json['id'] as String,
                categoryId: 'customer',
                name: json['name'] as String? ?? '',
                email: json['email'] as String?,
                phoneNumber: json['phoneNumber'] as String?,
                avatarUrl: json['avatarUrl'] as String?,
                loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
                vehicleCount: json['_count']?['ownedVehicles'] as int? ?? 0,
                createdAt: DateTime.parse(json['createdAt'] as String),
              ))
          .toList();
    }

    throw Exception('Tìm kiếm khách hàng thất bại');
  }

  Future<List<TechnicianLookupResult>> _searchTechnicians(String? query) async {
    final queryParams = <String, dynamic>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['search'] = query.trim();
    }

    final response = await dio.get(
      '/users/technicians',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data
          .map((json) => TechnicianLookupResult(
                id: json['id'] as String,
                categoryId: 'technician',
                name: json['name'] as String? ?? '',
                phoneNumber: json['phoneNumber'] as String?,
                activeJobCount: json['vehicleCount'] as int? ?? 0,
                isOnline: json['isOnline'] as bool? ?? false,
                updatedAt: DateTime.now(),
              ))
          .toList();
    }

    throw Exception('Tìm kiếm nhân viên thất bại');
  }

  VehicleLookupResult _vehicleModelToResult(VehicleModel v) {
    return VehicleLookupResult(
      id: v.id,
      categoryId: 'vehicle',
      licensePlate: v.licensePlate,
      brand: v.brand,
      model: v.model,
      color: v.color,
      imageUrl: v.imageUrl,
      manufactureYear: v.manufactureYear,
      currentKm: v.currentKm,
      warrantyExpiry: v.warrantyExpiry,
      ownerId: v.ownerId,
      ownerName: v.ownerName,
      ownerPhone: v.ownerPhone,
      createdAt: v.createdAt,
    );
  }

  @override
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await dio.put('/users/$userId', data: data);
  }
}

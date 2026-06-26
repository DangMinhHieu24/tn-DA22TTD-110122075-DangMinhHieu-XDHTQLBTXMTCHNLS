import 'package:dio/dio.dart';
import 'package:core/core.dart';
import '../../models/vehicle_detail_model.dart';
import '../../models/inventory_part_model.dart';
import '../../models/work_item_model.dart';

abstract class TechLookupRemoteDataSource {
  Future<VehicleDetailModel> searchVehicleByPlate(String licensePlate);
  Future<List<VehicleDetailModel>> getAllVehicles({String? query});
  Future<WarrantyResponse> getVehicleWarranties(String vehicleId);
  Future<List<InventoryPartModel>> getInventoryParts({String? query});
  Future<List<WorkItemModel>> searchWorkOrders({String? query, String? technicianId});
}

class TechLookupRemoteDataSourceImpl implements TechLookupRemoteDataSource {
  final Dio dio;

  TechLookupRemoteDataSourceImpl({required this.dio});

  @override
  Future<VehicleDetailModel> searchVehicleByPlate(String licensePlate) async {
    final response = await dio.get('/vehicles/plate/$licensePlate');

    if (response.data['success'] == true) {
      return VehicleDetailModel.fromApiJson(
          response.data['data'] as Map<String, dynamic>);
    }

    throw Exception('Không tìm thấy xe với biển số $licensePlate');
  }

  @override
  Future<List<VehicleDetailModel>> getAllVehicles({String? query}) async {
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
          .map((json) =>
              VehicleDetailModel.fromApiJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Không thể tải danh sách xe');
  }

  @override
  Future<WarrantyResponse> getVehicleWarranties(String vehicleId) async {
    final response =
        await dio.get('/warranties/vehicles/$vehicleId/warranties');

    if (response.data['success'] == true) {
      return WarrantyResponse.fromJson(
          response.data['data'] as Map<String, dynamic>);
    }

    throw Exception('Không thể tải thông tin bảo hành');
  }

  @override
  Future<List<InventoryPartModel>> getInventoryParts({String? query}) async {
    final queryParams = <String, dynamic>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['search'] = query.trim();
    }

    final response = await dio.get(
      '/inventory',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data
          .map((json) =>
              InventoryPartModel.fromApiJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Không thể tải danh sách phụ tùng');
  }

  @override
  Future<List<WorkItemModel>> searchWorkOrders({String? query, String? technicianId}) async {
    final queryParams = <String, dynamic>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['search'] = query.trim();
    }
    if (technicianId != null && technicianId.isNotEmpty) {
      queryParams['technicianId'] = technicianId;
    }

    final response = await dio.get(
      '/work-orders',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data
          .map((json) =>
              WorkItemModel.fromApiJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Không thể tải danh sách phiếu sửa chữa');
  }
}

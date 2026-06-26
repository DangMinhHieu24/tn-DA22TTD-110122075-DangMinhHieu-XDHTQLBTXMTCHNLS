import 'package:dio/dio.dart';
import '../../models/work_item_model.dart';
import '../../models/work_item_service_model.dart';

abstract class WorkRemoteDataSource {
  Future<List<WorkItemModel>> getWorkItems({String? technicianId});
  Future<WorkItemModel> getWorkItemById(String id);
  Future<WorkItemModel> updateWorkStatus(String id, String newStatus);
  Future<WorkItemServiceModel> updateWorkServiceStatus(
    String workOrderId,
    String serviceId,
    bool isDone,
  );
  Future<WorkItemServiceModel> addService(
    String workOrderId,
    String serviceType,
    String description, {
    String? serviceName,
    double? price,
  });
  Future<void> addParts(String workOrderId, List<Map<String, dynamic>> parts);
  Future<void> updateNotes(String workOrderId, String notes);
  Future<void> addPhoto(String workOrderId, String photoUrl, {String? photoType, String? description});
  Future<List<WorkItemModel>> searchWorkItems(String query, {String? technicianId});
}

class WorkRemoteDataSourceImpl implements WorkRemoteDataSource {
  final Dio dio;
  
  WorkRemoteDataSourceImpl({required this.dio});
  
  @override
  Future<List<WorkItemModel>> getWorkItems({String? technicianId}) async {
    try {
      // Call real API endpoint
      final response = await dio.get(
        '/work-orders',
        queryParameters: technicianId != null
            ? {'technicianId': technicianId}
            : null,
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => WorkItemModel.fromApiJson(json)).toList();
      }
      
      throw Exception('Failed to load work items');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<WorkItemModel> getWorkItemById(String id) async {
    try {
      final response = await dio.get('/work-orders/$id');
      
      if (response.data['success'] == true) {
        return WorkItemModel.fromApiJson(response.data['data']);
      }
      
      throw Exception('Failed to load work item');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<WorkItemModel> updateWorkStatus(String id, String newStatus) async {
    try {
      final response = await dio.patch(
        '/work-orders/$id/status',
        data: {'status': newStatus},
      );
      
      if (response.data['success'] == true) {
        return WorkItemModel.fromApiJson(response.data['data']);
      }
      
      throw Exception('Failed to update work status');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<WorkItemServiceModel> updateWorkServiceStatus(
    String workOrderId,
    String serviceId,
    bool isDone,
  ) async {
    try {
      final response = await dio.patch(
        '/work-orders/$workOrderId/services/$serviceId',
        data: {'isDone': isDone},
      );

      if (response.data['success'] == true) {
        return WorkItemServiceModel.fromApiJson(response.data['data']);
      }

      throw Exception('Failed to update service status');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<WorkItemServiceModel> addService(
    String workOrderId,
    String serviceType,
    String description, {
    String? serviceName,
    double? price,
  }) async {
    try {
      final response = await dio.post(
        '/work-orders/$workOrderId/services',
        data: {
          'serviceType': serviceType,
          'description': description,
          'serviceName': serviceName,
          'price': price,
        },
      );

      if (response.data['success'] == true) {
        return WorkItemServiceModel.fromApiJson(response.data['data']);
      }

      throw Exception('Failed to add service');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addParts(String workOrderId, List<Map<String, dynamic>> parts) async {
    try {
      final normalizedParts = parts
          .where((p) => (p['quantity'] as int? ?? 0) > 0)
          .map((p) => {
            'partId': p['id'],
            'quantity': p['quantity'],
            'unitPrice': p['price'],
          })
          .toList();

      if (normalizedParts.isEmpty) return;

      await dio.patch(
        '/work-orders/$workOrderId/parts',
        data: {'partsUsed': normalizedParts},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addPhoto(String workOrderId, String photoUrl, {String? photoType, String? description}) async {
    try {
      await dio.post(
        '/work-orders/$workOrderId/photos',
        data: {
          'photoUrl': photoUrl,
          'photoType': photoType ?? 'AFTER_REPAIR',
          'description': description,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateNotes(String workOrderId, String notes) async {
    try {
      await dio.put(
        '/work-orders/$workOrderId',
        data: {'notes': notes},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<WorkItemModel>> searchWorkItems(
    String query, {
    String? technicianId,
  }) async {
    try {
      // Search by calling getWorkItems and filter locally for now
      // TODO: Implement server-side search if needed
      final items = await getWorkItems(technicianId: technicianId);
      
      if (query.isEmpty) return items;
      
      return items.where((item) {
        final q = query.toLowerCase();
        return item.licensePlate.toLowerCase().contains(q) ||
            item.customerName.toLowerCase().contains(q) ||
            item.vehicleModel.toLowerCase().contains(q);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}

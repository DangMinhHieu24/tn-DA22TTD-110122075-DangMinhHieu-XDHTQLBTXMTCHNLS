import 'dart:io';
import 'package:dio/dio.dart';
import 'package:core/core.dart';
import '../datasources/remote/vehicle_remote_datasource.dart';
import '../datasources/remote/work_order_remote_datasource.dart';
import '../models/technician_model.dart';
import '../models/vehicle_model.dart';
import '../models/work_order_model.dart';

class VehicleIntakeRepository {
  final VehicleRemoteDataSource vehicleDataSource;
  final WorkOrderRemoteDataSource workOrderDataSource;
  final ImageUploadService imageUploadService;
  final Dio dio;

  VehicleIntakeRepository({
    required this.vehicleDataSource,
    required this.workOrderDataSource,
    required this.imageUploadService,
    required this.dio,
  });

  /// Search vehicle by license plate
  Future<VehicleModel?> searchVehicle(String licensePlate) async {
    try {
      return await vehicleDataSource.getVehicleByLicensePlate(licensePlate);
    } catch (e) {
      rethrow;
    }
  }

  /// Get vehicle repair history
  Future<List<WorkOrderModel>> getVehicleHistory(String vehicleId) async {
    try {
      return await workOrderDataSource.getWorkOrdersByVehicleId(vehicleId);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new vehicle record
  Future<VehicleModel> createVehicle({
    required String licensePlate,
    required String ownerId,
    String? brand,
    required String model,
    String? color,
    int? manufactureYear,
    String? qrCode,
    DateTime? warrantyExpiry,
    int? currentKm,
    String? imageUrl,
  }) async {
    try {
      return await vehicleDataSource.createVehicle({
        'licensePlate': licensePlate,
        if (brand != null) 'brand': brand,
        'model': model,
        if (color != null) 'color': color,
        if (manufactureYear != null) 'manufactureYear': manufactureYear,
        if (qrCode != null) 'qrCode': qrCode,
        if (warrantyExpiry != null) 'warrantyExpiry': warrantyExpiry.toIso8601String(),
        if (currentKm != null) 'currentKm': currentKm,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'ownerId': ownerId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createVehicleOwner({
    required String name,
    required String phoneNumber,
    String? email,
    String? password,
  }) async {
    try {
      final sanitizedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final finalEmail = email ?? 'owner.$sanitizedPhone.${DateTime.now().millisecondsSinceEpoch}@auto.local';
      final finalPassword = password ?? 'AutoPwd${DateTime.now().millisecondsSinceEpoch % 1000000}';

      final response = await dio.post(
        '/auth/register',
        data: {
          'name': name,
          'phoneNumber': phoneNumber,
          'email': finalEmail,
          'password': finalPassword,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final userData = response.data['user'] as Map<String, dynamic>?;
        if (userData != null && userData['id'] != null) {
          return userData['id'] as String;
        }
      }

      throw Exception('Failed to create vehicle owner');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TechnicianModel>> getTechnicians() async {
    try {
      final response = await dio.get('/users/technicians');
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => TechnicianModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch technicians');
    } catch (e) {
      rethrow;
    }
  }

  /// Create work order (vehicle intake)
  Future<WorkOrderModel> createWorkOrder({
    required String vehicleId,
    required String notes,
    required List<String> serviceTypes,
    String? technicianId,
    double? estimatedHours,
    List<File>? photoFiles,
    int? currentKm,
    String? appointmentId,
  }) async {
    try {
      // Upload ảnh lên Firebase Storage nếu có
      List<String>? photoUrls;
      if (photoFiles != null && photoFiles.isNotEmpty) {
        photoUrls = await imageUploadService.uploadMultipleImages(
          imageFiles: photoFiles,
          folder: 'work_orders/$vehicleId',
        );
      }

      // Build services array with default prices
      final services = serviceTypes.map((type) {
        return {
          'serviceType': _mapServiceType(type),
          'description': _getServiceDescription(type),
          'price': _getServicePrice(type),
        };
      }).toList();

      // Build photos array (if any)
      final photos = photoUrls?.map((url) {
        return {
          'photoUrl': url,
          'description': 'Vehicle photo',
        };
      }).toList();

      final data = {
        'vehicleId': vehicleId,
        'status': 'PENDING',
        'notes': notes,
        'technicianId': _normalizeTechnicianId(technicianId),
        'estimatedHours': estimatedHours,
        if (currentKm != null) 'currentKm': currentKm,
        'services': services,
        if (photos != null && photos.isNotEmpty) 'photos': photos,
        if (appointmentId != null) 'appointmentId': appointmentId,
      };

      return await workOrderDataSource.createWorkOrder(data);
    } catch (e) {
      rethrow;
    }
  }

  String? _normalizeTechnicianId(String? technicianId) {
    if (technicianId == null || technicianId == 'auto') {
      return null;
    }

    final uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegExp.hasMatch(technicianId) ? technicianId : null;
  }

  String _mapServiceType(String type) {
    switch (type) {
      case 'maintenance':
        return 'MAINTENANCE';
      case 'battery':
        return 'BATTERY_CHECK';
      case 'brakes':
        return 'BRAKES_TIRES';
      case 'other':
        return 'OTHER_REPAIR';
      default:
        return 'OTHER_REPAIR';
    }
  }

  String _getServiceDescription(String type) {
    switch (type) {
      case 'maintenance':
        return 'Bảo dưỡng định kỳ';
      case 'battery':
        return 'Kiểm tra pin/sạc';
      case 'brakes':
        return 'Phanh & Lốp';
      case 'other':
        return 'Sửa chữa khác';
      default:
        return '';
    }
  }

  double _getServicePrice(String type) {
    switch (type) {
      case 'maintenance':
        return 200000;
      case 'battery':
        return 150000;
      case 'brakes':
        return 250000;
      case 'other':
        return 200000;
      default:
        return 0;
    }
  }
}

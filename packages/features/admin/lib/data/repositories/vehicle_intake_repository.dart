import 'dart:io';
import 'package:core/core.dart';
import '../datasources/remote/vehicle_remote_datasource.dart';
import '../datasources/remote/work_order_remote_datasource.dart';
import '../models/vehicle_model.dart';
import '../models/work_order_model.dart';

class VehicleIntakeRepository {
  final VehicleRemoteDataSource vehicleDataSource;
  final WorkOrderRemoteDataSource workOrderDataSource;
  final ImageUploadService imageUploadService;

  VehicleIntakeRepository({
    required this.vehicleDataSource,
    required this.workOrderDataSource,
    required this.imageUploadService,
  });

  /// Search vehicle by license plate
  Future<VehicleModel?> searchVehicle(String licensePlate) async {
    try {
      return await vehicleDataSource.getVehicleByLicensePlate(licensePlate);
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

      // Build services array
      final services = serviceTypes.map((type) {
        return {
          'serviceType': _mapServiceType(type),
          'description': _getServiceDescription(type),
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
        'priority': 'NORMAL',
        'notes': notes,
        'technicianId': technicianId == 'auto' ? null : technicianId,
        'estimatedHours': estimatedHours,
        'services': services,
        if (photos != null && photos.isNotEmpty) 'photos': photos,
      };

      return await workOrderDataSource.createWorkOrder(data);
    } catch (e) {
      rethrow;
    }
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
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../src/models/warranty_model.dart';

class WarrantyService {
  final String baseUrl;
  final Future<String> Function() getToken;

  WarrantyService({
    required this.baseUrl,
    required this.getToken,
  });

  Future<WarrantyResponse> getVehicleWarranties(String vehicleId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/warranties/vehicles/$vehicleId/warranties'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return WarrantyResponse.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load warranties');
        }
      } else if (response.statusCode == 403) {
        throw Exception('Bạn không có quyền xem thông tin bảo hành của xe này');
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy xe');
      } else {
        throw Exception('Failed to load warranties: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading warranties: $e');
    }
  }

  Future<List<WarrantyModel>> getAllWarranties({
    String? status,
    bool? expiringSoon,
  }) async {
    try {
      final token = await getToken();
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (expiringSoon != null) queryParams['expiringSoon'] = expiringSoon.toString();

      final uri = Uri.parse('$baseUrl/warranties').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return (jsonData['data'] as List)
              .map((w) => WarrantyModel.fromJson(w))
              .toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load warranties');
        }
      } else {
        throw Exception('Failed to load warranties: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading warranties: $e');
    }
  }

  Future<WarrantyModel> createWarranty({
    required String vehicleId,
    required String warrantyType,
    required DateTime startDate,
    required DateTime expiryDate,
    String? terms,
    String? issuedBy,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/warranties'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'vehicleId': vehicleId,
          'warrantyType': warrantyType,
          'startDate': startDate.toIso8601String(),
          'expiryDate': expiryDate.toIso8601String(),
          'terms': terms,
          'issuedBy': issuedBy,
        }),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return WarrantyModel.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to create warranty');
        }
      } else {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to create warranty');
      }
    } catch (e) {
      throw Exception('Error creating warranty: $e');
    }
  }

  Future<WarrantyModel> updateWarranty({
    required String warrantyId,
    String? warrantyType,
    DateTime? startDate,
    DateTime? expiryDate,
    String? terms,
    String? issuedBy,
  }) async {
    try {
      final token = await getToken();
      final body = <String, dynamic>{};
      if (warrantyType != null) body['warrantyType'] = warrantyType;
      if (startDate != null) body['startDate'] = startDate.toIso8601String();
      if (expiryDate != null) body['expiryDate'] = expiryDate.toIso8601String();
      if (terms != null) body['terms'] = terms;
      if (issuedBy != null) body['issuedBy'] = issuedBy;

      final response = await http.put(
        Uri.parse('$baseUrl/warranties/$warrantyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return WarrantyModel.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to update warranty');
        }
      } else {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to update warranty');
      }
    } catch (e) {
      throw Exception('Error updating warranty: $e');
    }
  }

  Future<void> deleteWarranty(String warrantyId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/warranties/$warrantyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] != true) {
          throw Exception(jsonData['message'] ?? 'Failed to delete warranty');
        }
      } else {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to delete warranty');
      }
    } catch (e) {
      throw Exception('Error deleting warranty: $e');
    }
  }
}

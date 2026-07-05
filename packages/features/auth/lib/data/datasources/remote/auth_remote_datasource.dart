import 'package:dio/dio.dart';
import '../../models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  });
  
  Future<AuthResponseModel> register({
    required String name,
    required String phoneNumber,
    required String email,
    required String password,
  });
  
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  
  // Local development
  // iOS Simulator: use localhost
  // Android Emulator: use 10.0.2.2
  // Real device: use your computer's IP (e.g., 192.168.1.100)
  static const String baseUrl = 'https://nanglungsach-api.onrender.com/api';

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/auth/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return AuthResponseModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Login failed',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Email/Số điện thoại hoặc mật khẩu không đúng');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Tài khoản không tồn tại');
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Kết nối timeout. Vui lòng thử lại');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối đến server');
      }
      throw Exception(e.message ?? 'Đã xảy ra lỗi');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String name,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/auth/register',
        data: {
          'name': name,
          'phoneNumber': phoneNumber,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthResponseModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Registration failed',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Email hoặc số điện thoại đã được sử dụng');
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Kết nối timeout. Vui lòng thử lại');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối đến server');
      }
      throw Exception(e.message ?? 'Đã xảy ra lỗi');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post('$baseUrl/auth/logout');
    } catch (e) {
      // Logout locally even if API call fails
    }
  }
}

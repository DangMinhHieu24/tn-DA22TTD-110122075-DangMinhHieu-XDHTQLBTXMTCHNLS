import 'package:dio/dio.dart';
import '../datasources/local/auth_local_datasource.dart';

class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource localDataSource;

  AuthInterceptor({required this.localDataSource});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get token from local storage
    final token = await localDataSource.getToken();
    
    if (token != null) {
      // Add token to headers
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 Unauthorized - token expired
    if (err.response?.statusCode == 401) {
      // Clear local storage
      localDataSource.deleteToken();
      localDataSource.deleteUser();
    }
    
    handler.next(err);
  }
}

import 'package:dio/dio.dart';
import '../services/secure_storage_service.dart';

/// Interceptor that automatically adds JWT token to requests
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for login endpoint
    if (options.path.contains('/auth/login')) {
      return handler.next(options);
    }

    final token = await _secureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 Unauthorized - token expired or invalid
    if (err.response?.statusCode == 401) {
      // Could emit an event or clear token here
      // For now, just pass the error through
    }
    handler.next(err);
  }
}

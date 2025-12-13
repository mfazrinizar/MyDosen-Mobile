import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

enum ApiEndpoint {
  primary,
  // routing,
}

class ApiEndpoints {
  static String baseUrl(ApiEndpoint endpoint) {
    switch (endpoint) {
      case ApiEndpoint.primary:
        return dotenv.env['API_URL_PRIMARY']?.trim() ??
            'https://api-mydosen.mfazrinizar.com';
      // case ApiEndpoint.routing:
      //   return dotenv.env['API_URL_ROUTING']?.trim() ?? 'https://routing.example';
    }
  }

  // API version prefix
  static const String apiVersion = '/api/v1';

  // Auth endpoints
  static const String login = '$apiVersion/auth/login';
  static const String profile = '$apiVersion/auth/profile';

  // Admin endpoints
  static const String adminUsers = '$apiVersion/admin/users';
  static String adminUserById(String id) => '$apiVersion/admin/users/$id';
  static const String adminPermissions = '$apiVersion/admin/permissions';

  // Tracking endpoints
  static const String trackingRequest = '$apiVersion/tracking/request';
  static const String trackingMyRequests = '$apiVersion/tracking/my-requests';
  static const String trackingAllowedDosen =
      '$apiVersion/tracking/allowed-dosen';
  static const String trackingDosen = '$apiVersion/tracking/dosen';
  static const String trackingPending = '$apiVersion/tracking/pending';
  static const String trackingHandle = '$apiVersion/tracking/handle';
  static const String trackingHistory = '$apiVersion/tracking/history';
  static const String trackingStudents = '$apiVersion/tracking/students';

  // Socket.IO path
  static const String socketPath = '$apiVersion/io';
}

// Centralized factory
class DioFactory {
  static Dio create(ApiEndpoint endpoint,
      {BaseOptions? options, String? authToken}) {
    final baseOptions = options ??
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl(endpoint),
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        );

    final dio = Dio(baseOptions);

    // Common interceptors
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      compact: true,
    ));

    // Simple auth interceptor
    final token = authToken ?? dotenv.env['API_AUTH_TOKEN'];
    if (token != null && token.isNotEmpty) {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ));
    }

    // Simple retry interceptor for transient network failures
    dio.interceptors
        .add(RetryOnConnectionChangeInterceptor(dio: dio, retries: 2));

    return dio;
  }
}

// Small retry interceptor implementation
class RetryOnConnectionChangeInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  RetryOnConnectionChangeInterceptor({required this.dio, this.retries = 1});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final shouldRetry = _shouldRetry(err);
    if (shouldRetry && err.requestOptions.extra['retryCount'] == null) {
      var options = err.requestOptions;
      var attempt = 0;
      while (attempt < retries) {
        attempt++;
        try {
          final reqOptions = Options(
            method: options.method,
            headers: options.headers,
            responseType: options.responseType,
            extra: {...options.extra, 'retryCount': attempt},
          );
          final response = await dio.request(
            options.path,
            data: options.data,
            queryParameters: options.queryParameters,
            options: reqOptions,
          );
          return handler.resolve(response);
        } catch (_) {}
      }
    }
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;
  }
}

// ApiClient & typed wrappers
class ApiClient {
  final ApiEndpoint endpoint;
  final Dio dio;

  ApiClient(this.endpoint, {Dio? dio})
      : dio = dio ?? Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl(endpoint)));

  Future<Response> get(String path,
          {Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken}) =>
      dio.get(path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response> post(String path,
          {dynamic data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken}) =>
      dio.post(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response> put(String path,
          {dynamic data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken}) =>
      dio.put(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response> delete(String path,
          {dynamic data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken}) =>
      dio.delete(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response> patch(String path,
          {dynamic data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken}) =>
      dio.patch(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);
}

// Typed wrapper to avoid instanceName lookups in DI
class PrimaryApiClient extends ApiClient {
  PrimaryApiClient({Dio? dio}) : super(ApiEndpoint.primary, dio: dio);
}

// Authenticated API client that uses SecureStorageService for JWT
class AuthenticatedApiClient extends ApiClient {
  AuthenticatedApiClient(Dio dio) : super(ApiEndpoint.primary, dio: dio);
}

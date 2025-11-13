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
            'https://primary.example';
      // case ApiEndpoint.routing:
      //   return dotenv.env['API_URL_ROUTING']?.trim() ?? 'https://routing.example';
    }
  }
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
}

// Typed wrapper to avoid instanceName lookups in DI
class PrimaryApiClient extends ApiClient {
  PrimaryApiClient({Dio? dio}) : super(ApiEndpoint.primary, dio: dio);
}

import 'package:dio/dio.dart';

/// Singleton Dio HTTP client.
/// Configured with baseUrl, timeouts, and interceptors.
/// Swap [baseUrl] to production URL before release.
class DioClient {
  late final Dio _dio;

  DioClient({String baseUrl = 'https://api.gptraveladvisor.com/v1'}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
      _AuthInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}

/// Attaches Bearer token to every request (once auth is implemented).
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: attach token from secure storage when auth is implemented
    // final token = await secureStorage.read(key: 'access_token');
    // if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO: handle 401 → refresh token logic here
    handler.next(err);
  }
}

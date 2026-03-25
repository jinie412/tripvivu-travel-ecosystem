import 'package:dio/dio.dart';
import 'api_config.dart';

/// Singleton Dio HTTP client.
/// Configured with baseUrl, timeouts, and interceptors.
/// Swap [baseUrl] to production URL before release.
class DioClient {
  late final Dio _dio;

  DioClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.baseUrl,
        // connectTimeout: const Duration(seconds: 15),
        // receiveTimeout: const Duration(seconds: 15),
        // sendTimeout: const Duration(seconds: 15),
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
    // Ví dụ: Lấy token từ local storage hoặc session
    // final token = await secureStorage.read(key: 'access_token');
    const token = 'YOUR_ACCESS_TOKEN_HERE'; // Thay thế bằng logic lấy token thực tế
    
    // Tự động đính kèm token vào mọi request
    // ignore: dead_code
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO: handle 401 → refresh token logic here
    handler.next(err);
  }
}

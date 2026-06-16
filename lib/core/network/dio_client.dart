import 'api_config.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Singleton Dio HTTP client.
/// Configured with baseUrl, timeouts, auth injection, response cache, and 401 retry.
class DioClient {
  late final Dio _dio;

  static final _cacheOptions = CacheOptions(
    store: MemCacheStore(
      maxSize: 10 * 1024 * 1024,     // 10 MB tổng
      maxEntrySize: 2 * 1024 * 1024, // 2 MB mỗi entry
    ),
    policy: CachePolicy.forceCache,
    maxStale: const Duration(minutes: 5),
    priority: CachePriority.high,
    allowPostMethod: false,
  );

  DioClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.baseUrl,
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
      DioCacheInterceptor(options: _cacheOptions),
      _AuthInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  /// Trả về Options có header bypass cache — dùng khi user pull-to-refresh.
  Options get forceRefreshOptions => Options(
        extra: _cacheOptions
            .copyWith(policy: CachePolicy.refresh)
            .toExtra(),
      );
}

/// Đính kèm Bearer token từ SecureStorage vào mỗi request.
/// Khi nhận 401, tự động gọi /auth/refresh rồi retry request gốc 1 lần.
class _AuthInterceptor extends Interceptor {
  final _storage = const FlutterSecureStorage();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Chỉ xử lý 401 và không retry vô hạn
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['_retried'] != true) {
      try {
        final refreshToken = await _storage.read(key: 'refresh_token');
        if (refreshToken == null || refreshToken.isEmpty) {
          handler.next(err);
          return;
        }

        final refreshDio = Dio(BaseOptions(
          baseUrl: err.requestOptions.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

        final refreshResponse = await refreshDio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final newAccessToken =
            refreshResponse.data['accessToken'] as String?;
        final newRefreshToken =
            refreshResponse.data['refreshToken'] as String?;

        if (newAccessToken == null || newAccessToken.isEmpty) {
          handler.next(err);
          return;
        }

        await Future.wait([
          _storage.write(key: 'access_token', value: newAccessToken),
          if (newRefreshToken != null)
            _storage.write(key: 'refresh_token', value: newRefreshToken),
        ]);

        final retryOptions = err.requestOptions.copyWith(
          headers: {
            ...err.requestOptions.headers,
            'Authorization': 'Bearer $newAccessToken',
          },
          extra: {
            ...err.requestOptions.extra,
            '_retried': true,
          },
        );

        final retryResponse = await Dio().fetch(retryOptions);
        handler.resolve(retryResponse);
        return;
      } catch (_) {
        // Refresh thất bại → xoá token cũ, để app điều hướng về màn login
        await Future.wait([
          _storage.delete(key: 'access_token'),
          _storage.delete(key: 'refresh_token'),
        ]);
      }
    }

    handler.next(err);
  }
}

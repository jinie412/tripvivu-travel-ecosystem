import 'dart:async';

import 'api_config.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:travel_advisor_mobile/core/services/auth_storage.dart';

/// Singleton Dio HTTP client.
/// Configured with baseUrl, timeouts, auth injection, response cache, and 401 retry.
class DioClient {
  late final Dio _dio;

  static final _cacheOptions = CacheOptions(
    store: MemCacheStore(
      maxSize: 10 * 1024 * 1024,
      maxEntrySize: 2 * 1024 * 1024,
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
      _AuthInterceptor(_dio),
    ]);
  }

  Dio get dio => _dio;

  /// Trả về Options có header bypass cache — dùng khi user pull-to-refresh.
  Options get forceRefreshOptions => Options(
        extra: _cacheOptions
            .copyWith(policy: CachePolicy.refresh)
            .toExtra(),
      );

  /// Xóa toàn bộ HTTP response cache (in-memory).
  /// Bắt buộc phải gọi khi logout: cache được key theo URL chứ không theo user,
  /// nên nếu không xóa, user B đăng nhập lại có thể vẫn nhận response cache của user A
  /// (vd. GET /profile/tourist/me) trong lúc maxStale còn hiệu lực.
  Future<void> clearCache() => _cacheOptions.store!.clean();
}

/// Đính kèm Bearer token từ SecureStorage vào mỗi request.
/// Khi nhận 401, tự động gọi /auth/refresh rồi retry request gốc 1 lần.
/// Dùng Completer để chống concurrent refresh khi nhiều request cùng hết hạn.
class _AuthInterceptor extends Interceptor {
  final Dio _dio;

  /// null = không có refresh nào đang chạy.
  /// non-null = refresh đang chạy, giá trị future trả về true nếu thành công.
  Completer<bool>? _refreshCompleter;

  _AuthInterceptor(this._dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AuthStorage.read('access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Chỉ xử lý 401 và không retry vô hạn
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['_retried'] == true) {
      handler.next(err);
      return;
    }

    // Nếu đang có refresh chạy, chờ nó xong rồi retry với token mới
    final existing = _refreshCompleter;
    if (existing != null) {
      final success = await existing.future;
      if (success) {
        await _retryRequest(err, handler);
      } else {
        handler.next(err);
      }
      return;
    }

    // Bắt đầu một lần refresh mới
    _refreshCompleter = Completer<bool>();
    try {
      final refreshToken = await AuthStorage.read('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        handler.next(err);
        return;
      }

      // Gọi /auth/refresh bằng _dio đã cấu hình sẵn.
      // extra['_retried'] = true để tránh interceptor tự loop khi refresh cũng trả 401.
      final refreshResponse = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'_retried': true}),
      );

      final newAccessToken = refreshResponse.data['accessToken'] as String?;
      final newRefreshToken = refreshResponse.data['refreshToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        await _clearTokens();
        handler.next(err);
        return;
      }

      await Future.wait([
          AuthStorage.write('access_token', newAccessToken),
          if (newRefreshToken != null && newRefreshToken.isNotEmpty)
            AuthStorage.write('refresh_token', newRefreshToken),
      ]);

      _refreshCompleter!.complete(true);
      _refreshCompleter = null;

      await _retryRequest(err, handler);
    } catch (_) {
      _refreshCompleter?.complete(false);
      _refreshCompleter = null;
      await _clearTokens();
      handler.next(err);
    }
  }

  Future<void> _retryRequest(
      DioException err, ErrorInterceptorHandler handler) async {
    try {
      final newToken = await AuthStorage.read('access_token');
      final retryOptions = err.requestOptions.copyWith(
        headers: {
          ...err.requestOptions.headers,
          'Authorization': 'Bearer $newToken',
        },
        extra: {
          ...err.requestOptions.extra,
          '_retried': true,
        },
      );
      // Dùng _dio (cùng instance đã cấu hình) thay vì Dio() trần.
      handler.resolve(await _dio.fetch(retryOptions));
    } catch (e) {
      handler.next(err);
    }
  }

  Future<void> _clearTokens() async {
    await Future.wait([
      AuthStorage.delete('access_token'),
      AuthStorage.delete('refresh_token'),
      AuthStorage.delete('cached_user'),
    ]);
  }
}

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

class _TimeoutHttpFileService extends HttpFileService {
  _TimeoutHttpFileService() : super(httpClient: http.Client());

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) {
    return super
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 20));
  }
}

/// Global cache manager for all network images.
/// - 20s HTTP timeout (prevents hanging on slow hosts)
/// - 7-day stale period, up to 300 cached objects
/// - Single shared instance to avoid duplicate disk writes
class AppImageCacheManager extends CacheManager with ImageCacheManager {
  static const _key = 'gp_travel_img_v1';

  static final AppImageCacheManager _instance = AppImageCacheManager._();
  factory AppImageCacheManager() => _instance;

  AppImageCacheManager._()
      : super(
          Config(
            _key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 300,
            fileService: _TimeoutHttpFileService(),
          ),
        );
}

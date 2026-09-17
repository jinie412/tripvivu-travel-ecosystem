import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:travel_advisor_mobile/core/config/app_config.dart';

/// Kết quả 1 chặng đường: toạ độ để vẽ + có phải đường thẳng dự phòng hay
/// không (khi Goong lỗi/hết quota) để UI vẽ khác kiểu (nét đứt, màu nhạt)
/// thay vì trông giống hệt tuyến đường thật.
class GoongRouteResult {
  final List<mapbox.Position> points;
  final bool isFallback;

  const GoongRouteResult(this.points, this.isFallback);
}

class MapUtils {
  /// Sinh ra URL ảnh bản đồ tĩnh dựa trên cấu hình trong AppConfig
  static String getStaticMapUrl(
    double lat,
    double lng, {
    int width = 600,
    int height = 300,
    int zoom = 15,
  }) {
    if (AppConfig.kMapProvider == 'goong') {
      // API Goong Static Map
      return 'https://maps.goong.io/staticmap?center=$lat,$lng&zoom=$zoom&size=${width}x$height&markers=color:red|$lat,$lng&api_key=${AppConfig.kGoongMaptilesKey}';
    } else {
      // API Google Static Map
      return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=$zoom&size=${width}x$height&markers=color:red|$lat,$lng&key=${AppConfig.kGoogleMapKey}';
    }
  }

  /// Sinh ra link dẫn đường tới một địa điểm
  static String getDirectionUrl(double lat, double lng, {String? name}) {
    final latStr = lat.toStringAsFixed(6);
    final lngStr = lng.toStringAsFixed(6);
    final query = name != null
        ? Uri.encodeComponent('$name, $latStr,$lngStr')
        : '$latStr,$lngStr';
    return 'https://www.google.com/maps/search/?api=1&query=$query';
  }

  /// Sinh ra link chỉ đường từ điểm xuất phát đến điểm đến (Google Maps).
  /// [travelMode] là giá trị lưu ở backend ('DRIVING'/'MOTORBIKE') — map sang
  /// travelmode của Google Maps để không luôn mặc định "driving" khi lịch
  /// trình dùng xe máy.
  static String getDirectionsUrl(
    double originLat,
    double originLng,
    double destLat,
    double destLng, {
    String travelMode = 'DRIVING',
  }) {
    final googleTravelMode = travelMode.toUpperCase() == 'MOTORBIKE'
        ? 'two-wheeler'
        : 'driving';
    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=${originLat.toStringAsFixed(6)},${originLng.toStringAsFixed(6)}'
        '&destination=${destLat.toStringAsFixed(6)},${destLng.toStringAsFixed(6)}'
        '&travelmode=$googleTravelMode';
  }

  // ─── Cache + throttle cho Goong Direction API ───────────────────────
  // Goong rate-limit theo giây (xem log backend "OVER_RATE_LIMIT"/429).
  // Trước đây mỗi ItineraryMapView tự cache trong RAM riêng (mất khi đóng
  // màn hình) và bắn request tuần tự không giới hạn tốc độ — bấm "Tất cả"
  // trên 1 lịch trình nhiều ngày dễ dội hàng chục request cùng lúc. Cache
  // này ở cấp app (sống hết vòng đời process) + hàng đợi tuần tự có giãn
  // cách tối thiểu giữa 2 request để không lặp lại tình trạng đó.
  static final Map<String, GoongRouteResult> _routeCache = {};
  static const Duration _minRequestGap = Duration(milliseconds: 250);
  static Future<void> _requestQueue = Future.value();

  static Future<T> _enqueueThrottled<T>(Future<T> Function() task) {
    final previous = _requestQueue;
    final completer = Completer<T>();
    _requestQueue = previous.then((_) async {
      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      }
      await Future.delayed(_minRequestGap);
    });
    return completer.future;
  }

  /// Lấy danh sách tọa độ uốn lượn theo đường đi thực tế từ Goong.
  /// [travelMode] map 'MOTORBIKE' -> Goong 'bike', mặc định 'car'.
  ///
  /// Trả về [GoongRouteResult.isFallback] = true khi Goong lỗi/hết quota —
  /// lúc đó [GoongRouteResult.points] là đường thẳng nối 2 đầu (không phải
  /// tuyến đường thật) để UI luôn vẽ được gì đó thay vì biến mất trắng trơn,
  /// nhưng caller nên vẽ nét đứt/màu nhạt để không gây hiểu lầm là đường đi
  /// chính xác.
  static Future<GoongRouteResult> getGoongRoute(
    List<mapbox.Position> waypoints, {
    String travelMode = 'DRIVING',
  }) async {
    if (waypoints.length < 2) {
      return GoongRouteResult(waypoints, false);
    }

    final origin = '${waypoints.first.lat},${waypoints.first.lng}';
    final destination = '${waypoints.last.lat},${waypoints.last.lng}';
    final vehicle = travelMode.toUpperCase() == 'MOTORBIKE' ? 'bike' : 'car';
    final cacheKey = '$origin>$destination>$vehicle';

    final cached = _routeCache[cacheKey];
    if (cached != null) return cached;

    final result = await _enqueueThrottled(
      () => _fetchGoongRoute(origin, destination, vehicle, waypoints),
    );
    _routeCache[cacheKey] = result;
    return result;
  }

  static Future<GoongRouteResult> _fetchGoongRoute(
    String origin,
    String destination,
    String vehicle,
    List<mapbox.Position> waypoints,
  ) async {
    final url =
        'https://rsapi.goong.io/v2/direction?origin=$origin&destination=$destination&vehicle=$vehicle&api_key=${AppConfig.kGoongApiKey}';

    try {
      final response = await Dio().get(url);
      if (response.statusCode == 200 && response.data['routes'].isNotEmpty) {
        final encodedPolyline =
            response.data['routes'][0]['overview_polyline']['points'];
        final PolylinePoints polylinePoints = PolylinePoints();
        final List<PointLatLng> result = polylinePoints.decodePolyline(
          encodedPolyline,
        );

        return GoongRouteResult(
          result
              .map((p) => mapbox.Position(p.longitude, p.latitude))
              .toList(),
          false,
        );
      }
    } catch (e) {
      debugPrint('Error fetching Goong route: $e');
    }

    // Goong lỗi/hết quota (429...) — vẽ tạm đường thẳng nối 2 đầu thay vì
    // không vẽ gì. Caller chịu trách nhiệm style khác (nét đứt/nhạt) vì
    // đường thẳng có thể cắt ngang nhà/sông, không phải tuyến thật.
    return GoongRouteResult(waypoints, true);
  }
}

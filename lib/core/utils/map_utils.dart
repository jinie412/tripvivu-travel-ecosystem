import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:travel_advisor_mobile/core/config/app_config.dart';

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

  /// Sinh ra link chỉ đường từ điểm xuất phát đến điểm đến (Google Maps)
  static String getDirectionsUrl(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) {
    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=${originLat.toStringAsFixed(6)},${originLng.toStringAsFixed(6)}'
        '&destination=${destLat.toStringAsFixed(6)},${destLng.toStringAsFixed(6)}';
  }

  /// Lấy danh sách tọa độ uốn lượn theo đường đi thực tế từ Goong
  static Future<List<mapbox.Position>> getGoongRoute(
    List<mapbox.Position> waypoints,
  ) async {
    if (waypoints.length < 2) return waypoints;

    final origin = '${waypoints.first.lat},${waypoints.first.lng}';
    final destination = '${waypoints.last.lat},${waypoints.last.lng}';

    // API v2 hỗ trợ origin và destination. Nếu có waypoints trung gian, v2 cũng xử lý tốt hơn
    final url =
        'https://rsapi.goong.io/v2/direction?origin=$origin&destination=$destination&vehicle=car&api_key=${AppConfig.kGoongApiKey}';

    try {
      final response = await Dio().get(url);
      if (response.statusCode == 200 && response.data['routes'].isNotEmpty) {
        final encodedPolyline =
            response.data['routes'][0]['overview_polyline']['points'];
        final PolylinePoints polylinePoints = PolylinePoints();
        final List<PointLatLng> result = polylinePoints.decodePolyline(
          encodedPolyline,
        );

        return result
            .map((p) => mapbox.Position(p.longitude, p.latitude))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching Goong route: $e');
    }

    // Do not draw a straight-line fallback: it can cut through buildings/water.
    return const [];
  }
}

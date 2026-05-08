import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:travel_advisor_mobile/core/config/app_config.dart';

class MapUtils {
  /// Sinh ra URL ảnh bản đồ tĩnh dựa trên cấu hình trong AppConfig
  static String getStaticMapUrl(double lat, double lng, {int width = 600, int height = 300, int zoom = 15}) {
    if (AppConfig.kMapProvider == 'goong') {
      return AppConfig.kGoongStaticMapUrl
          .replaceAll('{lat}', lat.toString())
          .replaceAll('{lng}', lng.toString())
          .replaceAll('{zoom}', zoom.toString())
          .replaceAll('{width}', width.toString())
          .replaceAll('{height}', height.toString())
          .replaceAll('{api_key}', AppConfig.kGoongMaptilesKey);
    } else {
      return AppConfig.kGoogleStaticMapUrl
          .replaceAll('{lat}', lat.toString())
          .replaceAll('{lng}', lng.toString())
          .replaceAll('{zoom}', zoom.toString())
          .replaceAll('{width}', width.toString())
          .replaceAll('{height}', height.toString())
          .replaceAll('{api_key}', AppConfig.kGoogleMapKey);
    }
  }

  /// Sinh ra link dẫn đường
  static String getDirectionUrl(double lat, double lng, {String? name}) {
    final query = name != null ? '$name, $lat,$lng' : '$lat,$lng';
    return AppConfig.kExternalMapSearchUrl.replaceAll('{query}', Uri.encodeComponent(query));
  }

  /// Lấy danh sách tọa độ uốn lượn theo đường đi thực tế từ Goong
  static Future<List<mapbox.Position>> getGoongRoute(List<mapbox.Position> waypoints) async {
    if (waypoints.length < 2) return waypoints;

    final origin = '${waypoints.first.lat},${waypoints.first.lng}';
    final destination = '${waypoints.last.lat},${waypoints.last.lng}';
    
    // API v2 hỗ trợ origin và destination. Nếu có waypoints trung gian, v2 cũng xử lý tốt hơn
    final url = AppConfig.kGoongDirectionApiUrl
        .replaceAll('{origin}', origin)
        .replaceAll('{destination}', destination)
        .replaceAll('{api_key}', AppConfig.kGoongApiKey);

    try {
      final response = await Dio().get(url);
      if (response.statusCode == 200 && response.data['routes'].isNotEmpty) {
        final encodedPolyline = response.data['routes'][0]['overview_polyline']['points'];
        final PolylinePoints polylinePoints = PolylinePoints();
        final List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);
        
        return result.map((p) => mapbox.Position(p.longitude, p.latitude)).toList();
      }
    } catch (e) {
      print('Error fetching Goong route: $e');
    }
    
    // Fallback: trả về đường thẳng nếu lỗi
    return waypoints;
  }
}

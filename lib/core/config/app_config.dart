import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// 🔧 TRUNG TÂM ĐIỀU KHIỂN CHẾ ĐỘ DEMO
  static const bool kUseMockData = true; 
  static const bool kSkipLogin = true;

  /// 🗺️ CẤU HÌNH BẢN ĐỒ
  static String get kMapProvider => 'goong'; 
  
  static String get kGoongMaptilesKey => dotenv.env['GOONG_MAPTILES_KEY'] ?? '';
  static String get kGoongApiKey => dotenv.env['GOONG_API_KEY'] ?? '';
  static String get kGoogleMapKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  static String get kGoongMapStyle {
    final baseUrl = dotenv.env['GOONG_MAP_STYLE'] ?? 'https://tiles.goong.io/assets/goong_map_web.json';
    return '$baseUrl?api_key=$kGoongMaptilesKey';
  }

  /// 🏎️ DIRECTION API TEMPLATES
  static const String kGoongDirectionApiUrl = "https://rsapi.goong.io/v2/direction?origin={origin}&destination={destination}&vehicle=car&api_key={api_key}";

  /// 🖼️ STATIC MAP TEMPLATES
  static const String kGoongStaticMapUrl = "https://maps.goong.io/staticmap?center={lat},{lng}&zoom={zoom}&size={width}x{height}&markers=color:red|{lat},{lng}&api_key={api_key}";
  static const String kGoogleStaticMapUrl = "https://maps.googleapis.com/maps/api/staticmap?center={lat},{lng}&zoom={zoom}&size={width}x{height}&markers=color:red|{lat},{lng}&key={api_key}";

  /// 🔗 ĐƯỜNG DẪN BẢN ĐỒ NGOÀI
  static const String kExternalMapSearchUrl = "https://www.google.com/maps/search/?api=1&query={query}";
}

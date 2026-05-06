import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// 🔧 TRUNG TÂM ĐIỀU KHIỂN CHẾ ĐỘ DEMO
  /// - true: Dùng dữ liệu mẫu (Mock data), bỏ qua Login, Backend.
  /// - false: Kết nối API thật, yêu cầu Login.
  static const bool kUseMockData = true; 

  /// Tự động bỏ qua màn hình đăng nhập nếu đang ở chế độ Demo
  static const bool kSkipLogin = true;

  /// 🗺️ CẤU HÌNH BẢN ĐỒ
  static String get kMapProvider => 'goong'; 
  
  /// Key cho Map Tiles (hiển thị hình ảnh bản đồ) - dùng trong Style URL
  static String get kGoongMaptilesKey => dotenv.env['GOONG_MAPTILES_KEY'] ?? '';
  
  /// Key cho API (Direction, Autocomplete, Geocode) - dùng khi gọi rsapi.goong.io
  static String get kGoongApiKey => dotenv.env['GOONG_API_KEY'] ?? '';
  
  static String get kGoogleMapKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  /// Goong Map Style URL - Dùng MAPTILES KEY để load tiles
  static String get kGoongMapStyle {
    final baseUrl = dotenv.env['GOONG_MAP_STYLE'] ?? 'https://tiles.goong.io/assets/goong_map_web.json';
    return '$baseUrl?api_key=$kGoongMaptilesKey';
  }
}

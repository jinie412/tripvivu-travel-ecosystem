import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/tracking_models.dart';
import '../tracking_config.dart';

/// Ngữ cảnh theo dõi được lưu xuống đĩa để **background isolate** (geofence
/// callback / AlarmManager) có thể tự gọi BE mà không cần DI của app.
///
/// Isolate nền không chia sẻ memory với app, cũng không load `flutter_dotenv`,
/// nên ta phải persist `baseUrl`, `touristId`, `itineraryId`, ngày và thông tin
/// từng điểm dừng (tên + ngưỡng dwell) ngay lúc bấm "Bắt đầu".
class TrackingContext {
  final String baseUrl;
  final String touristId;
  final String itineraryId;
  final String date; // yyyy-MM-dd
  final int radiusM;

  /// itineraryDetailId -> { name, dwell(seconds) }
  final Map<String, TrackingPlaceMeta> places;

  const TrackingContext({
    required this.baseUrl,
    required this.touristId,
    required this.itineraryId,
    required this.date,
    required this.radiusM,
    required this.places,
  });

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'touristId': touristId,
        'itineraryId': itineraryId,
        'date': date,
        'radiusM': radiusM,
        'places': places.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory TrackingContext.fromJson(Map<String, dynamic> j) => TrackingContext(
        baseUrl: j['baseUrl']?.toString() ?? '',
        touristId: j['touristId']?.toString() ?? '',
        itineraryId: j['itineraryId']?.toString() ?? '',
        date: j['date']?.toString() ?? '',
        radiusM: (j['radiusM'] as num?)?.toInt() ?? TrackingConfig.radiusM,
        places: ((j['places'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(
            k.toString(),
            TrackingPlaceMeta.fromJson(Map<String, dynamic>.from(v as Map)),
          ),
        ),
      );

  TrackingPlaceMeta? metaFor(String itineraryDetailId) =>
      places[itineraryDetailId];
}

class TrackingPlaceMeta {
  final String name;
  final int dwellSeconds;

  const TrackingPlaceMeta({required this.name, required this.dwellSeconds});

  Map<String, dynamic> toJson() => {'name': name, 'dwell': dwellSeconds};

  factory TrackingPlaceMeta.fromJson(Map<String, dynamic> j) =>
      TrackingPlaceMeta(
        name: j['name']?.toString() ?? 'địa điểm',
        dwellSeconds: (j['dwell'] as num?)?.toInt() ?? TrackingConfig.dwellSeconds,
      );
}

/// Đọc/ghi [TrackingContext] qua SharedPreferences (dùng được ở cả hai isolate).
class TrackingContextStore {
  static const _key = 'itinerary_tracking_context';

  static Future<void> save(TrackingContext ctx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ctx.toJson()));
  }

  static Future<TrackingContext?> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Đảm bảo đọc giá trị mới nhất nếu isolate khác vừa ghi.
    await prefs.reload();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return TrackingContext.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // ── Ngày kế tiếp cần đăng ký lại (AlarmManager sáng hôm sau) ──────────────
  static const _nextDateKey = 'itinerary_tracking_next_date';

  static Future<void> saveNextDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nextDateKey, date);
  }

  static Future<String?> loadNextDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(_nextDateKey);
  }

  static Future<void> clearNextDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nextDateKey);
  }

  // ── Food spots persistence (lat/lng của quán ăn trong lịch trình) ──────────
  static const _foodSpotsKey = 'tracking_food_spots';

  static Future<void> saveFoodSpots(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_foodSpotsKey, json);
  }

  static Future<String?> loadFoodSpots() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(_foodSpotsKey);
  }

  static Future<void> clearFoodSpots() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_foodSpotsKey);
  }

  // ── Last callback error (debug) ─────────────────────────────────────────────
  static const _lastErrorKey = 'tracking_last_callback_error';

  static Future<void> saveLastError(String error) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastErrorKey, '[${DateTime.now().toIso8601String()}] $error');
  }

  static Future<String?> loadLastError() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastErrorKey);
  }

  static Future<void> clearLastError() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastErrorKey);
  }

  /// Tạo context từ danh sách geofence của ngày.
  static TrackingContext build({
    required String baseUrl,
    required String touristId,
    required String itineraryId,
    required String date,
    required int radiusM,
    required List<TrackingGeofence> geofences,
  }) {
    final places = <String, TrackingPlaceMeta>{};
    for (final g in geofences) {
      if (g.itineraryDetailId.isEmpty) continue;
      places[g.itineraryDetailId] = TrackingPlaceMeta(
        name: (g.name == null || g.name!.isEmpty) ? 'địa điểm' : g.name!,
        dwellSeconds: g.dwellThresholdSeconds,
      );
    }
    return TrackingContext(
      baseUrl: baseUrl,
      touristId: touristId,
      itineraryId: itineraryId,
      date: date,
      radiusM: radiusM,
      places: places,
    );
  }
}

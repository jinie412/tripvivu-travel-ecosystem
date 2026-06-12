import 'package:native_geofence/native_geofence.dart';

import '../data/models/tracking_models.dart';
import 'geofence_callback.dart';

/// Đăng ký / gỡ geofence với Google Play Services qua native_geofence.
///
/// Mỗi điểm dừng = 1 geofence hình tròn (tâm + bán kính). Region `id` đặt bằng
/// `itineraryDetailId` để callback nền biết điểm nào kích hoạt.
/// `loiteringDelay` = ngưỡng dwell → sự kiện DWELL bắn sau khi ở lại đủ lâu.
class GeofenceTrackingService {
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await NativeGeofenceManager.instance.initialize();
    _initialized = true;
  }

  /// Đăng ký toàn bộ geofence của một ngày. Trả về số geofence đăng ký thành công.
  Future<int> registerAll(
    List<TrackingGeofence> geofences, {
    Duration? expiration,
  }) async {
    await _ensureInit();
    var ok = 0;
    for (final g in geofences) {
      if (g.itineraryDetailId.isEmpty || !g.hasValidLocation) continue;
      try {
        final geofence = Geofence(
          id: g.itineraryDetailId,
          location: Location(latitude: g.latitude, longitude: g.longitude),
          radiusMeters: g.radiusM.toDouble(),
          // ENTER để ghi mốc, DWELL để tính "Đã ghé", EXIT để đóng mốc.
          triggers: const {
            GeofenceEvent.enter,
            GeofenceEvent.dwell,
            GeofenceEvent.exit,
          },
          iosSettings: const IosGeofenceSettings(initialTrigger: true),
          androidSettings: AndroidGeofenceSettings(
            initialTriggers: const {GeofenceEvent.enter},
            loiteringDelay: Duration(seconds: g.dwellThresholdSeconds),
            notificationResponsiveness: const Duration(seconds: 30),
            expiration: expiration,
          ),
        );
        await NativeGeofenceManager.instance
            .createGeofence(geofence, geofenceTriggered);
        ok++;
      } catch (_) {
        // bỏ qua geofence lỗi, tiếp tục các điểm còn lại
      }
    }
    return ok;
  }

  /// Gỡ một số geofence theo itineraryDetailId (dùng khi kết thúc ngày).
  Future<void> removeByIds(List<String> ids) async {
    await _ensureInit();
    for (final id in ids) {
      if (id.isEmpty) continue;
      try {
        await NativeGeofenceManager.instance.removeGeofenceById(id);
      } catch (_) {}
    }
  }

  /// Gỡ tất cả geofence đang theo dõi.
  Future<void> removeAll() async {
    await _ensureInit();
    try {
      await NativeGeofenceManager.instance.removeAllGeofences();
    } catch (_) {}
  }

  Future<List<String>> registeredIds() async {
    await _ensureInit();
    try {
      return await NativeGeofenceManager.instance.getRegisteredGeofenceIds();
    } catch (_) {
      return const [];
    }
  }
}

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum TrackingPermResult { granted, serviceOff, deniedForeground, deniedBackground }

/// Xin quyền theo đúng luồng use case (bước 2): vị trí + **Always Allow /
/// Background Location**, kèm quyền thông báo (Android 13+).
class TrackingPermissions {
  static Future<TrackingPermResult> ensure() async {
    // 1) Dịch vụ định vị bật chưa?
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return TrackingPermResult.serviceOff;

    // 2) Quyền vị trí khi dùng app.
    var whenInUse = await Permission.locationWhenInUse.status;
    if (!whenInUse.isGranted) {
      whenInUse = await Permission.locationWhenInUse.request();
    }
    if (!whenInUse.isGranted) return TrackingPermResult.deniedForeground;

    // 3) Quyền nền (Always Allow) — bắt buộc cho geofence chạy nền.
    var always = await Permission.locationAlways.status;
    if (!always.isGranted) {
      always = await Permission.locationAlways.request();
    }
    if (!always.isGranted) return TrackingPermResult.deniedBackground;

    // 4) Quyền thông báo (không bắt buộc, để hiện push "Đã đến nơi").
    final notif = await Permission.notification.status;
    if (!notif.isGranted) {
      await Permission.notification.request();
    }

    return TrackingPermResult.granted;
  }

  static String messageFor(TrackingPermResult r) {
    switch (r) {
      case TrackingPermResult.serviceOff:
        return 'Vui lòng bật Dịch vụ vị trí (GPS) để theo dõi lịch trình.';
      case TrackingPermResult.deniedForeground:
        return 'Cần quyền truy cập vị trí để theo dõi lịch trình.';
      case TrackingPermResult.deniedBackground:
        return 'Cần quyền vị trí "Luôn cho phép" (Always Allow) để theo dõi khi tắt app. '
            'Mở Cài đặt → Quyền → Vị trí → Luôn cho phép.';
      case TrackingPermResult.granted:
        return '';
    }
  }
}

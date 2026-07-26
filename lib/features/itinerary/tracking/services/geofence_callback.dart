import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:native_geofence/native_geofence.dart';

import '../data/models/tracking_models.dart';
import '../tracking_config.dart';
import 'tracking_context.dart';
import 'tracking_http.dart';

/// Hàm chạy trong **background isolate** mỗi khi geofence kích hoạt
/// (ENTER / DWELL / EXIT). Phải là top-level + `@pragma('vm:entry-point')`
/// để native_geofence gọi lại được sau khi app bị kill.
@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  // Isolate nền: cần khởi tạo binding + plugin registrant thủ công.
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final ctx = await TrackingContextStore.load();
  if (ctx == null || ctx.baseUrl.isEmpty) {
    debugPrint('[Geofence] ERR: context null hoặc baseUrl rỗng');
    return;
  }

  final eventType = _eventTypeOf(params.event);
  if (eventType == null) return;

  debugPrint('[Geofence] $eventType fired for ${params.geofences.length} region(s). touristId=${ctx.touristId}');

  final dio = await buildTrackingDio(ctx.baseUrl);

  for (final g in params.geofences) {
    final detailId = g.id; // region id = itineraryDetailId
    final meta = ctx.metaFor(detailId);
    try {
      final res = await dio.post('/itinerary/tracking/event', data: {
        'itineraryDetailId': detailId,
        'touristId': ctx.touristId,
        'eventType': eventType,
        'occurredAt': DateTime.now().toIso8601String(),
        if (eventType == 'DWELL') 'dwellSeconds': meta?.dwellSeconds ?? TrackingConfig.dwellSeconds,
      });

      final result = GeofenceEventResult.fromAny(res.data);
      debugPrint('[Geofence] $eventType → detailId=$detailId status=${result.status}');

      // Backend tạo một FCM notification có payload mở chi tiết lịch trình.
    } catch (e) {
      // Ghi log để trace qua ADB logcat: adb logcat | grep Geofence
      debugPrint('[Geofence] ERR send event $eventType detailId=$detailId: $e');
      await TrackingContextStore.saveLastError('$eventType $detailId: $e');
    }
  }
}
String? _eventTypeOf(GeofenceEvent e) {
  switch (e) {
    case GeofenceEvent.enter:
      return 'ENTER';
    case GeofenceEvent.dwell:
      return 'DWELL';
    case GeofenceEvent.exit:
      return 'EXIT';
  }
}

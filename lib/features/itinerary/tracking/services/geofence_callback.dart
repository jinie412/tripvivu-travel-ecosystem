import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:native_geofence/native_geofence.dart';

import '../data/models/tracking_models.dart';
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
  if (ctx == null || ctx.baseUrl.isEmpty) return;

  final eventType = _eventTypeOf(params.event);
  if (eventType == null) return;

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
        if (eventType == 'DWELL') 'dwellSeconds': meta?.dwellSeconds ?? 120,
      });

      final result = GeofenceEventResult.fromAny(res.data);
      // Đủ dwell -> "Đã ghé" -> bắn push "Bạn đã đến [Tên địa điểm]".
      if (eventType == 'DWELL' && result.status == VisitStatus.visited) {
        await _showArrivalNotification(
          detailId: detailId,
          placeName: result.name ?? meta?.name ?? 'địa điểm',
        );
      }
    } catch (_) {
      // Nuốt lỗi mạng ở isolate nền — lần event sau sẽ thử lại.
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

Future<void> _showArrivalNotification({
  required String detailId,
  required String placeName,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await plugin.initialize(settings: initSettings);

  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'itinerary_tracking_channel',
      'Theo dõi lịch trình',
      channelDescription: 'Thông báo khi bạn đến một địa điểm trong lịch trình',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    ),
    iOS: DarwinNotificationDetails(),
  );

  await plugin.show(
    id: detailId.hashCode & 0x7fffffff,
    title: 'Đã đến nơi 🎉',
    body: 'Bạn đã đến $placeName',
    notificationDetails: details,
    payload: 'tracking:$detailId',
  );
}

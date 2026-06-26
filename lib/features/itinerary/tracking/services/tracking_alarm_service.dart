import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';

import '../data/models/tracking_models.dart';
import 'geofence_tracking_service.dart';
import 'tracking_context.dart';
import 'tracking_http.dart';

/// Đặt lịch AlarmManager cho vòng lặp theo ngày của use case:
///  - 23h: kết thúc ngày (remove geofence + mark skipped) → đặt alarm sáng hôm sau.
///  - sáng hôm sau: đăng ký lại geofence cho ngày mới → đặt alarm 23h ngày đó.
class TrackingAlarmService {
  static const int endOfDayAlarmId = 990001;
  static const int nextDayAlarmId = 990002;

  Future<void> scheduleEndOfDay(DateTime at) async {
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.oneShotAt(
      at, endOfDayAlarmId, onTrackingDayEnd,
      exact: true, wakeup: true,
      rescheduleOnReboot: true, allowWhileIdle: true,
    );
  }

  Future<void> scheduleNextDay(DateTime at) async {
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.oneShotAt(
      at, nextDayAlarmId, onTrackingNextDay,
      exact: true, wakeup: true,
      rescheduleOnReboot: true, allowWhileIdle: true,
    );
  }

  Future<void> cancelAll() async {
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.cancel(endOfDayAlarmId);
    await AndroidAlarmManager.cancel(nextDayAlarmId);
  }
}

/// 23h — kết thúc ngày: gọi `/end-day`, remove geofence, đặt alarm ngày kế.
@pragma('vm:entry-point')
Future<void> onTrackingDayEnd() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final ctx = await TrackingContextStore.load();
  if (ctx == null || ctx.baseUrl.isEmpty) return;

  try {
    final dio = await buildTrackingDio(ctx.baseUrl);
    final res = await dio.post('/itinerary/tracking/end-day', data: {
      'itineraryId': ctx.itineraryId,
      'date': ctx.date,
      'markPendingAsSkipped': true,
    });
    final end = EndDayResult.fromAny(res.data);

    // Remove geofence trên thiết bị.
    final ids = end.removedItineraryDetailIds.isNotEmpty
        ? end.removedItineraryDetailIds
        : ctx.places.keys.toList();
    await GeofenceTrackingService().removeByIds(ids);

    // Còn ngày kế → đặt alarm sáng hôm sau để đăng ký lại.
    final hasNext =
        end.itineraryStatus != 'completed' && end.nextDayDate != null;
    if (hasNext) {
      final next = end.nextDayDate!;
      await TrackingContextStore.saveNextDate(
        '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}',
      );
      final alarmAt = end.nextDayAlarmAt ??
          DateTime(next.year, next.month, next.day, 7);
      await TrackingAlarmService().scheduleNextDay(alarmAt);
    } else {
      // Hết lịch trình → dọn ngữ cảnh.
      await TrackingContextStore.clear();
      await TrackingContextStore.clearNextDate();
    }
  } catch (e) {
    // Lỗi mạng: lưu lại để debug, giữ nguyên context để app đồng bộ khi mở lại.
    await TrackingContextStore.saveLastError('onTrackingDayEnd: $e');
  }
}

/// Sáng hôm sau — đăng ký lại geofence cho ngày mới, đặt alarm 23h ngày đó.
@pragma('vm:entry-point')
Future<void> onTrackingNextDay() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final ctx = await TrackingContextStore.load();
  final nextDate = await TrackingContextStore.loadNextDate();
  if (ctx == null || ctx.baseUrl.isEmpty || nextDate == null) return;

  try {
    final dio = await buildTrackingDio(ctx.baseUrl);
    // Dùng POST /start thay vì GET /geofences để BE tạo geofence_visits cho ngày mới.
    final res = await dio.post('/itinerary/tracking/start', data: {
      'itineraryId': ctx.itineraryId,
      'touristId': ctx.touristId,
      'date': nextDate,
      'radiusM': ctx.radiusM,
    });
    final geofences = TrackingStartResult.fromAny(res.data).geofences;
    if (geofences.isEmpty) return;

    await GeofenceTrackingService().registerAll(geofences);

    // Cập nhật context sang ngày mới.
    final newCtx = TrackingContextStore.build(
      baseUrl: ctx.baseUrl,
      touristId: ctx.touristId,
      itineraryId: ctx.itineraryId,
      date: nextDate,
      radiusM: ctx.radiusM,
      geofences: geofences,
    );
    await TrackingContextStore.save(newCtx);
    await TrackingContextStore.clearNextDate();

    // Đặt alarm kết thúc ngày mới lúc 23:00.
    final p = nextDate.split('-');
    if (p.length == 3) {
      final endAt = DateTime(
          int.parse(p[0]), int.parse(p[1]), int.parse(p[2]), 23, 0);
      await TrackingAlarmService().scheduleEndOfDay(endAt);
    }
  } catch (e) {
    await TrackingContextStore.saveLastError('onTrackingNextDay: $e');
  }
}

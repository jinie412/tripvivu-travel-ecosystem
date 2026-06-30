/// Models cho tính năng "Theo dõi lịch trình" (geofence + dwell time).
///
/// Khớp với BE `api-service` module `itinerary-tracking` (base `/itinerary/tracking`).
/// Parse JSON theo kiểu "lenient": chấp nhận nhiều biến thể key (camelCase/snake_case)
/// để bền với thay đổi nhỏ phía BE.
library;

import 'package:travel_advisor_mobile/features/itinerary/tracking/tracking_config.dart';

// ───────────────────────── helpers parse linh hoạt ─────────────────────────
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int _toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

String? _toStr(dynamic v) => v?.toString();

/// Lấy giá trị đầu tiên không null trong nhiều key có thể có.
dynamic _pick(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) return j[k];
  }
  return null;
}

/// Trạng thái ghé của một điểm dừng.
enum VisitStatus { notVisited, visited, skipped }

VisitStatus visitStatusFrom(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'visited':
      return VisitStatus.visited;
    case 'skipped':
      return VisitStatus.skipped;
    default:
      return VisitStatus.notVisited;
  }
}

// ───────────────────────── geofence để mobile đăng ký ─────────────────────────
/// Một vùng geofence trả về từ `/start` hoặc `/geofences`.
class TrackingGeofence {
  final String itineraryDetailId; // khoá định danh điểm dừng ở API
  final String? geofenceId;
  final String? placeId;
  final String? name; // tên địa điểm (để hiển thị thông báo)
  final double latitude;
  final double longitude;
  final int radiusM;
  final int dwellThresholdSeconds; // ngưỡng dwell -> "Đã ghé"

  const TrackingGeofence({
    required this.itineraryDetailId,
    required this.latitude,
    required this.longitude,
    this.geofenceId,
    this.placeId,
    this.name,
    this.radiusM = TrackingConfig.radiusM,
    this.dwellThresholdSeconds = TrackingConfig.dwellSeconds,
  });

  factory TrackingGeofence.fromJson(Map<String, dynamic> j) => TrackingGeofence(
        itineraryDetailId:
            _toStr(_pick(j, ['itineraryDetailId', 'itinerary_detail_id'])) ?? '',
        geofenceId: _toStr(_pick(j, ['geofenceId', 'geofence_id'])),
        placeId: _toStr(_pick(j, ['placeId', 'place_id'])),
        name: _toStr(_pick(j, ['name', 'placeName', 'place_name', 'title'])),
        latitude: _toDouble(_pick(j, ['latitude', 'lat'])) ?? 0,
        longitude: _toDouble(_pick(j, ['longitude', 'lng', 'lon'])) ?? 0,
        radiusM: _toInt(_pick(j, ['radiusM', 'radius_m', 'radius']), TrackingConfig.radiusM),
        dwellThresholdSeconds: _toInt(
          _pick(j, ['dwellThresholdSeconds', 'dwell_threshold_seconds']),
          TrackingConfig.dwellSeconds,
        ),
      );

  Map<String, dynamic> toJson() => {
        'itineraryDetailId': itineraryDetailId,
        'geofenceId': geofenceId,
        'placeId': placeId,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusM': radiusM,
        'dwellThresholdSeconds': dwellThresholdSeconds,
      };

  bool get hasValidLocation =>
      latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180 &&
      !(latitude == 0 && longitude == 0);
}

/// Kết quả `/start`.
class TrackingStartResult {
  final bool active;
  final String? itineraryId;
  final DateTime? date;
  final String? itineraryStatus;
  final List<TrackingGeofence> geofences;

  const TrackingStartResult({
    this.active = true,
    this.itineraryId,
    this.date,
    this.itineraryStatus,
    this.geofences = const [],
  });

  /// BE có thể trả về thẳng một List, hoặc object bọc trong `geofences`/`data`.
  factory TrackingStartResult.fromAny(dynamic body) {
    if (body is List) {
      return TrackingStartResult(
        active: true,
        geofences: body
            .whereType<Map>()
            .map((e) => TrackingGeofence.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }
    if (body is Map) {
      final m = Map<String, dynamic>.from(body);
      final raw = _pick(m, ['geofences', 'data', 'items']) as List? ?? const [];
      return TrackingStartResult(
        active: _pick(m, ['active']) != false,
        itineraryId: _toStr(_pick(m, ['itineraryId', 'itinerary_id'])),
        date: DateTime.tryParse(_toStr(_pick(m, ['date'])) ?? ''),
        itineraryStatus: _toStr(_pick(m, ['itineraryStatus', 'status'])),
        geofences: raw
            .whereType<Map>()
            .map((e) => TrackingGeofence.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }
    return const TrackingStartResult();
  }
}

// ───────────────────────── trạng thái bản đồ (/status) ─────────────────────────
class TrackingPlaceStatus {
  final String itineraryDetailId;
  final String? geofenceId;
  final String? placeId;
  final String? name;
  final VisitStatus status;
  final String statusLabelVi;
  final String? mapColor; // hex "#RRGGBB"
  final String? mapIcon; // pin / check / skip
  final int dwellSeconds;
  final DateTime? enteredAt;
  final DateTime? checkedInAt;
  final double? latitude;
  final double? longitude;

  const TrackingPlaceStatus({
    required this.itineraryDetailId,
    required this.status,
    required this.statusLabelVi,
    this.geofenceId,
    this.placeId,
    this.name,
    this.mapColor,
    this.mapIcon,
    this.dwellSeconds = 0,
    this.enteredAt,
    this.checkedInAt,
    this.latitude,
    this.longitude,
  });

  factory TrackingPlaceStatus.fromJson(Map<String, dynamic> j) {
    DateTime? dt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return TrackingPlaceStatus(
      itineraryDetailId:
          _toStr(_pick(j, ['itineraryDetailId', 'itinerary_detail_id'])) ?? '',
      geofenceId: _toStr(_pick(j, ['geofenceId', 'geofence_id'])),
      placeId: _toStr(_pick(j, ['placeId', 'place_id'])),
      name: _toStr(_pick(j, ['name', 'placeName', 'place_name', 'title'])),
      status: visitStatusFrom(_toStr(_pick(j, ['status']))),
      statusLabelVi:
          _toStr(_pick(j, ['statusLabelVi', 'status_label_vi'])) ?? 'Chưa ghé',
      mapColor: _toStr(_pick(j, ['mapColor', 'map_color'])),
      mapIcon: _toStr(_pick(j, ['mapIcon', 'map_icon'])),
      dwellSeconds: _toInt(_pick(j, ['dwellSeconds', 'dwell_seconds'])),
      enteredAt: dt(_pick(j, ['enteredAt', 'entered_at'])),
      checkedInAt: dt(_pick(j, ['checkedInAt', 'checked_in_at'])),
      latitude: _toDouble(_pick(j, ['latitude', 'lat'])),
      longitude: _toDouble(_pick(j, ['longitude', 'lng', 'lon'])),
    );
  }
}

class TrackingStatusResult {
  final int visited;
  final int skipped;
  final int notVisited;
  final int total;
  final List<TrackingPlaceStatus> places;

  const TrackingStatusResult({
    this.visited = 0,
    this.skipped = 0,
    this.notVisited = 0,
    this.total = 0,
    this.places = const [],
  });

  factory TrackingStatusResult.fromAny(dynamic body) {
    if (body is! Map) return const TrackingStatusResult();
    final m = Map<String, dynamic>.from(body);
    final summary = (_pick(m, ['summary']) as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final rawPlaces =
        _pick(m, ['places', 'items', 'data']) as List? ?? const [];
    return TrackingStatusResult(
      visited: _toInt(_pick(summary, ['visited'])),
      skipped: _toInt(_pick(summary, ['skipped'])),
      notVisited: _toInt(_pick(summary, ['notVisited', 'not_visited'])),
      total: _toInt(_pick(summary, ['total'])),
      places: rawPlaces
          .whereType<Map>()
          .map((e) => TrackingPlaceStatus.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

// ───────────────────────── kết quả gửi event / check-in ─────────────────────────
class GeofenceEventResult {
  final VisitStatus status;
  final bool notificationCreated;
  final String? statusLabelVi;
  final String? name;

  const GeofenceEventResult({
    required this.status,
    this.notificationCreated = false,
    this.statusLabelVi,
    this.name,
  });

  factory GeofenceEventResult.fromAny(dynamic body) {
    final m = body is Map
        ? Map<String, dynamic>.from(body)
        : const <String, dynamic>{};
    return GeofenceEventResult(
      status: visitStatusFrom(_toStr(_pick(m, ['status']))),
      notificationCreated:
          _pick(m, ['notificationCreated', 'notification_created']) == true,
      statusLabelVi: _toStr(_pick(m, ['statusLabelVi', 'status_label_vi'])),
      name: _toStr(_pick(m, ['name', 'placeName', 'place_name'])),
    );
  }
}

// ───────────────────────── kết quả kết thúc ngày (/end-day) ─────────────────────────
class EndDayResult {
  final List<String> removedGeofenceIds;
  final List<String> removedItineraryDetailIds;
  final List<String> removedPlaceIds;
  final DateTime? nextDayDate;
  final DateTime? nextDayAlarmAt;
  final String? itineraryStatus;

  const EndDayResult({
    this.removedGeofenceIds = const [],
    this.removedItineraryDetailIds = const [],
    this.removedPlaceIds = const [],
    this.nextDayDate,
    this.nextDayAlarmAt,
    this.itineraryStatus,
  });

  factory EndDayResult.fromAny(dynamic body) {
    final m = body is Map
        ? Map<String, dynamic>.from(body)
        : const <String, dynamic>{};
    List<String> ids(List<String> keys) {
      final raw = _pick(m, keys) as List? ?? const [];
      return raw.map((e) => e.toString()).toList();
    }

    DateTime? dt(List<String> keys) {
      final v = _pick(m, keys);
      return v == null ? null : DateTime.tryParse(v.toString());
    }

    return EndDayResult(
      removedGeofenceIds: ids(['removedGeofenceIds', 'removed_geofence_ids']),
      removedItineraryDetailIds:
          ids(['removedItineraryDetailIds', 'removed_itinerary_detail_ids']),
      removedPlaceIds: ids(['removedPlaceIds', 'removed_place_ids']),
      nextDayDate: dt(['nextDayDate', 'next_day_date']),
      nextDayAlarmAt: dt(['nextDayAlarmAt', 'next_day_alarm_at']),
      itineraryStatus: _toStr(_pick(m, ['itineraryStatus', 'itinerary_status'])),
    );
  }
}

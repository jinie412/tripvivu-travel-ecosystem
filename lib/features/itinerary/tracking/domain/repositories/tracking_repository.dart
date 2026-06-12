import '../../data/models/tracking_models.dart';

/// Hợp đồng cho tính năng theo dõi lịch trình (geofence + dwell).
abstract class TrackingRepository {
  Future<TrackingStartResult> start({
    required String itineraryId,
    required String touristId,
    required DateTime date,
    int radiusM,
  });

  Future<List<TrackingGeofence>> geofences({
    required String itineraryId,
    required DateTime date,
    int radiusM,
  });

  Future<GeofenceEventResult> sendEvent({
    required String itineraryDetailId,
    required String touristId,
    required String eventType,
    DateTime? occurredAt,
    int? dwellSeconds,
  });

  Future<GeofenceEventResult> checkIn({
    required String itineraryDetailId,
    required String touristId,
  });

  Future<TrackingStatusResult> status({
    required String itineraryId,
    required DateTime date,
  });

  Future<EndDayResult> endDay({
    required String itineraryId,
    required DateTime date,
    bool markPendingAsSkipped,
  });
}

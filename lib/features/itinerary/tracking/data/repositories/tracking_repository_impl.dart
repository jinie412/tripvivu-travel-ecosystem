import '../../domain/repositories/tracking_repository.dart';
import '../../tracking_config.dart';
import '../datasources/tracking_remote_datasource.dart';
import '../models/tracking_models.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingRemoteDataSource _remote;
  TrackingRepositoryImpl(this._remote);

  @override
  Future<TrackingStartResult> start({
    required String itineraryId,
    required String touristId,
    required DateTime date,
    int radiusM = TrackingConfig.radiusM,
  }) =>
      _remote.start(
        itineraryId: itineraryId,
        touristId: touristId,
        date: date,
        radiusM: radiusM,
      );

  @override
  Future<TrackingStartResult> active({
    required String touristId,
    int radiusM = TrackingConfig.radiusM,
  }) =>
      _remote.active(touristId: touristId, radiusM: radiusM);

  @override
  Future<List<TrackingGeofence>> geofences({
    required String itineraryId,
    required DateTime date,
    int radiusM = TrackingConfig.radiusM,
  }) =>
      _remote.geofences(itineraryId: itineraryId, date: date, radiusM: radiusM);

  @override
  Future<GeofenceEventResult> sendEvent({
    required String itineraryDetailId,
    required String touristId,
    required String eventType,
    DateTime? occurredAt,
    int? dwellSeconds,
  }) =>
      _remote.sendEvent(
        itineraryDetailId: itineraryDetailId,
        touristId: touristId,
        eventType: eventType,
        occurredAt: occurredAt,
        dwellSeconds: dwellSeconds,
      );

  @override
  Future<GeofenceEventResult> checkIn({
    required String itineraryDetailId,
    required String touristId,
  }) =>
      _remote.checkIn(itineraryDetailId: itineraryDetailId, touristId: touristId);

  @override
  Future<TrackingStatusResult> status({
    required String itineraryId,
    required DateTime date,
  }) =>
      _remote.status(itineraryId: itineraryId, date: date);

  @override
  Future<EndDayResult> endDay({
    required String itineraryId,
    required DateTime date,
    bool markPendingAsSkipped = true,
  }) =>
      _remote.endDay(
        itineraryId: itineraryId,
        date: date,
        markPendingAsSkipped: markPendingAsSkipped,
      );
}

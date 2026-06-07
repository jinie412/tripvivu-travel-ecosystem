import 'package:travel_advisor_mobile/features/itinerary/data/datasources/itinerary_datasource.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/create_itinerary_request_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';

/// Implementation cụ thể của [ItineraryRepository].
///
/// Delegate mọi thao tác sang [ItineraryDataSource] và chuyển đổi
/// Model → Entity trước khi trả về cho tầng Domain.
class ItineraryRepositoryImpl implements ItineraryRepository {
  final ItineraryDataSource _dataSource;
  ItineraryRepositoryImpl(this._dataSource);

  @override
  Future<List<ItineraryEntity>> getItineraries({
    ItineraryStatus? status,
  }) async {
    final models = await _dataSource.getItineraries();
    final entities = models.map((m) => m.toEntity()).toList();

    // Lọc theo status nếu có.
    if (status != null) {
      return entities.where((e) => e.status == status).toList();
    }
    return entities;
  }

  @override
  Future<ItinerarySummary> getSummary() async {
    final models = await _dataSource.getItineraries();
    final entities = models.map((m) => m.toEntity()).toList();

    return ItinerarySummary(
      total: entities.length,
      completed:
          entities.where((e) => e.status == ItineraryStatus.completed).length,
      upcoming:
          entities.where((e) => e.status == ItineraryStatus.upcoming).length,
      draft: entities.where((e) => e.status == ItineraryStatus.draft).length,
    );
  }

  @override
  Future<void> deleteItinerary(String id) async {
    await _dataSource.deleteItinerary(id);
  }

  @override
  Future<ItineraryDetailEntity> getItineraryDetail(String id) async {
    final model = await _dataSource.getItineraryDetail(id);
    return model.toEntity();
  }

  @override
  Future<void> updateItineraryActivities(String id, List<ItineraryDayEntity> days) async {
    await _dataSource.updateItineraryActivities(id, days);
  }

  @override
  Future<void> toggleVisibility(String id, bool isPublic) {
    return _dataSource.toggleVisibility(id, isPublic);
  }

  @override
  Future<void> updateItineraryTitle(String id, String title) {
    return _dataSource.updateItineraryTitle(id, title);
  }

  @override
  Future<void> updateActivity(
    String itineraryId,
    String activityId, {
    String? arrivalTime,
    String? departureTime,
    double? actualCost,
    String? userNotes,
    bool? isLocked,
  }) {
    return _dataSource.updateActivity(
      itineraryId,
      activityId,
      arrivalTime: arrivalTime,
      departureTime: departureTime,
      actualCost: actualCost,
      userNotes: userNotes,
      isLocked: isLocked,
    );
  }

  @override
  Future<void> deleteActivity(String itineraryId, String activityId) {
    return _dataSource.deleteActivity(itineraryId, activityId);
  }

  @override
  Future<String> createItinerary(CreateItineraryParams params) async {
    final request = CreateItineraryRequestModel(
      userId: params.userId,
      tripType: params.tripType,
      departureLocationId: params.departureLocationId,
      destinationLocationId: params.destinationLocationId,
      transportMode: params.transportMode,
      startDate: params.startDate,
      endDate: params.endDate,
      dailyStartTime: params.dailyStartTime,
      dailyEndTime: params.dailyEndTime,
      tripIntent: params.tripIntent,
      adultCount: params.adultCount,
      childCount: params.childCount,
      budget: params.budget,
      foodPreferences: params.foodPreferences,
    );
    return _dataSource.createItinerary(request);
  }
}
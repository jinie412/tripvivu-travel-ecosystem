import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/customize_activity_response_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

typedef ItineraryShareLink = ({
  String token,
  String deepLink,
  String shareUrl,
  String message,
  String? playStoreUrl,
});

typedef ItineraryShareRecipient = ({
  String id,
  String fullName,
  String email,
  String? phoneNumber,
});

abstract class ItineraryRepository {
  Future<List<ItineraryEntity>> getItineraries({
    ItineraryStatus? status,
    String? query,
  });
  Future<ItinerarySummary> getSummary();
  Future<ItineraryDetailEntity> getItineraryDetail(String id);
  Future<void> deleteItinerary(String id);
  Future<void> toggleVisibility(String id, bool isPublic);
  Future<void> shareItinerary(String id, String recipient);
  Future<List<ItineraryShareRecipient>> searchShareRecipients(String query);
  Future<ItineraryShareLink> createShareLink(String id);
  Future<void> updateItineraryTitle(String id, String title);
  Future<void> updateActivity(
    String itineraryId,
    String activityId, {
    String? arrivalTime,
    String? departureTime,
    double? actualCost,
    String? userNotes,
    bool? isLocked,
    bool? allowReduceTime,
    bool? extendTime,
  });
  Future<void> deleteActivity(String itineraryId, String activityId);

  /// Cập nhật danh sách hoạt động/thời gian của lịch trình theo [id].
  Future<void> updateItineraryActivities(
    String id,
    List<ItineraryDayEntity> days,
  );

  /// Tạo lịch trình mới qua AI pipeline.
  Future<CreateItineraryResult> createItinerary(CreateItineraryParams params);

  Future<CustomizeActivityResponseModel> addActivityToItinerary(
    String itineraryId,
    int dayNumber,
    String placeId, {
    String? preferredTime,
    bool isLocked = false,
    bool? allowReduceTime,
    bool? extendTime,
    bool? addExtraDay,
  });

  Future<CustomizeActivityResponseModel> replaceActivityInItinerary(
    String itineraryId,
    String activityId,
    String newPlaceId, {
    bool? allowReduceTime,
    bool? extendTime,
  });

  Future<({List<ItineraryActivityEntity> optimized, List<String> reorderNotes})>
  optimizeDay(String itineraryId, Map<String, dynamic> payload);
}

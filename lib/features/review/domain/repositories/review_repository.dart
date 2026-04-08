import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';

abstract class ReviewRepository {
  Future<ItineraryReviewEntity> getItineraryForReview(String itineraryId);
  Future<ItineraryReviewPopupData> getPopupData(String itineraryId);
  Future<void> dismissPopup(String itineraryId);
  Future<void> submitItineraryReview({
    required String itineraryId,
    double? overallRating,
    String? overallContent,
    bool applyAllPlaces = false,
    List<SubmitPlaceReviewInput> placeReviews = const [],
    List<String> mediaUrls = const [],
  });
}
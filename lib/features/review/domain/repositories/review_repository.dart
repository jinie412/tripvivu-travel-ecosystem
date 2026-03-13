import '../entities/itinerary_review_entity.dart';

abstract class ReviewRepository {
  Future<ItineraryReviewEntity> getItineraryForReview(String itineraryId);
}

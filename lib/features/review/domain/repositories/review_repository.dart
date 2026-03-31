import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';

abstract class ReviewRepository {
  Future<ItineraryReviewEntity> getItineraryForReview(String itineraryId);
}
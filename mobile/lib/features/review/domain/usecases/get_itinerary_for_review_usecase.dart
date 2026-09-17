import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';

class GetItineraryForReviewUseCase {
  final ReviewRepository repository;

  GetItineraryForReviewUseCase(this.repository);

  Future<ItineraryReviewEntity> call(
    String itineraryId, {
    bool forceRefresh = false,
  }) {
    return repository.getItineraryForReview(
      itineraryId,
      forceRefresh: forceRefresh,
    );
  }
}

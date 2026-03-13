import '../entities/itinerary_review_entity.dart';
import '../repositories/review_repository.dart';

class GetItineraryForReviewUseCase {
  final ReviewRepository repository;

  GetItineraryForReviewUseCase(this.repository);

  Future<ItineraryReviewEntity> call(String itineraryId) {
    return repository.getItineraryForReview(itineraryId);
  }
}

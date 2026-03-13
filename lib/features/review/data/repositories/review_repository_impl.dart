import '../../domain/entities/itinerary_review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewDataSource dataSource;

  ReviewRepositoryImpl(this.dataSource);

  @override
  Future<ItineraryReviewEntity> getItineraryForReview(String itineraryId) async {
    final model = await dataSource.getItineraryForReview(itineraryId);
    return model.toEntity();
  }
}

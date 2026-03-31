import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewDataSource dataSource;

  ReviewRepositoryImpl(this.dataSource);

  @override
  Future<ItineraryReviewEntity> getItineraryForReview(String itineraryId) async {
    final model = await dataSource.getItineraryForReview(itineraryId);
    return model.toEntity();
  }
}
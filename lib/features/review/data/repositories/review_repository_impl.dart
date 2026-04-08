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

  @override
  Future<ItineraryReviewPopupData> getPopupData(String itineraryId) {
    return dataSource.getPopupData(itineraryId);
  }

  @override
  Future<void> dismissPopup(String itineraryId) {
    return dataSource.dismissPopup(itineraryId);
  }

  @override
  Future<void> submitItineraryReview({
    required String itineraryId,
    double? overallRating,
    String? overallContent,
    bool applyAllPlaces = false,
    List<SubmitPlaceReviewInput> placeReviews = const [],
    List<String> mediaUrls = const [],
  }) {
    return dataSource.submitItineraryReview(
      itineraryId: itineraryId,
      overallRating: overallRating,
      overallContent: overallContent,
      applyAllPlaces: applyAllPlaces,
      placeReviews: placeReviews,
      mediaUrls: mediaUrls,
    );
  }
}
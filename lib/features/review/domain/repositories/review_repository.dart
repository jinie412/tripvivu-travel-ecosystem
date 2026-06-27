import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_types.dart';

abstract class ReviewRepository {
  Future<ReviewCatalog> getReviewCatalog();
  Future<ItineraryReviewEntity> getItineraryForReview(
    String itineraryId, {
    bool forceRefresh = false,
  });
  Future<SubmittedReviewData> getSubmittedReview(
    String itineraryId, {
    bool forceRefresh = false,
  });
  Future<ItineraryReviewSummary> getReviewSummary(String itineraryId);
  Future<ItineraryReviewPopupData> getPopupData(String itineraryId);
  Future<void> dismissPopup(String itineraryId);
  Future<void> submitItineraryReview({
    required String itineraryId,
    double? overallRating,
    String? overallContent,
    List<String> overallTags = const [],
    bool applyAllPlaces = false,
    List<SubmitPlaceReviewInput> placeReviews = const [],
    List<SubmitReviewMediaInput> media = const [],
  });
  Future<void> submitPlaceReview({
    required String placeId,
    String? itineraryId,
    required double rating,
    String? content,
    List<String> tags = const [],
    List<String> images = const [],
  });
  Future<List<ReviewMediaPresignedUrl>> createReviewPresignedUrls({
    required String scope,
    required String itineraryId,
    String? itineraryDetailId,
    required List<ReviewMediaUploadCandidate> files,
  });
  Future<void> uploadReviewMediaToR2({
    required ReviewMediaPresignedUrl presignedUrl,
    required String localPath,
    required String contentType,
    required int contentLength,
    void Function(int sent, int total)? onSendProgress,
  });
}

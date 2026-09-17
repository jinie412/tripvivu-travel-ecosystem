import 'dart:io';

import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewDataSource dataSource;

  ReviewRepositoryImpl(this.dataSource);

  ReviewCatalog? _catalogCache;
  DateTime? _catalogCachedAt;
  static const Duration _catalogTtl = Duration(seconds: 60);
  final Set<String> _dirtyItineraryIds = <String>{};

  @override
  Future<ReviewCatalog> getReviewCatalog() async {
    final now = DateTime.now();
    if (_catalogCache != null &&
        _catalogCachedAt != null &&
        now.difference(_catalogCachedAt!) < _catalogTtl) {
      return _catalogCache!;
    }
    final result = await dataSource.getReviewCatalog();
    _catalogCache = result;
    _catalogCachedAt = now;
    return result;
  }

  @override
  Future<ItineraryReviewEntity> getItineraryForReview(
    String itineraryId, {
    bool forceRefresh = false,
  }) async {
    final shouldRefresh =
        forceRefresh || _dirtyItineraryIds.contains(itineraryId);
    final model = await dataSource.getItineraryForReview(
      itineraryId,
      forceRefresh: shouldRefresh,
    );
    final entity = model.toEntity();
    if (shouldRefresh &&
        !entity.locations.any((location) => location.hasReview)) {
      _dirtyItineraryIds.remove(itineraryId);
    }
    return entity;
  }

  @override
  Future<SubmittedReviewData> getSubmittedReview(
    String itineraryId, {
    bool forceRefresh = false,
  }) {
    final shouldRefresh =
        forceRefresh || _dirtyItineraryIds.remove(itineraryId);
    return dataSource.getSubmittedReview(
      itineraryId,
      forceRefresh: shouldRefresh,
    );
  }

  @override
  Future<ItineraryReviewSummary> getReviewSummary(String itineraryId) {
    return dataSource.getReviewSummary(itineraryId);
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
    List<String> overallTags = const [],
    bool applyAllPlaces = false,
    List<SubmitPlaceReviewInput> placeReviews = const [],
    List<SubmitReviewMediaInput> media = const [],
  }) async {
    _catalogCache = null;
    await dataSource.submitItineraryReview(
      itineraryId: itineraryId,
      overallRating: overallRating,
      overallContent: overallContent,
      overallTags: overallTags,
      applyAllPlaces: applyAllPlaces,
      placeReviews: placeReviews,
      media: media,
    );
    _dirtyItineraryIds.add(itineraryId);
  }

  @override
  Future<void> submitPlaceReview({
    required String placeId,
    String? itineraryId,
    required double rating,
    String? content,
    List<String> tags = const [],
    List<String> images = const [],
  }) async {
    _catalogCache = null;
    await dataSource.submitPlaceReview(
      placeId: placeId,
      itineraryId: itineraryId,
      rating: rating,
      content: content,
      tags: tags,
      images: images,
    );
    final normalizedItineraryId = itineraryId?.trim() ?? '';
    if (normalizedItineraryId.isNotEmpty) {
      _dirtyItineraryIds.add(normalizedItineraryId);
    }
  }

  @override
  Future<List<ReviewMediaPresignedUrl>> createReviewPresignedUrls({
    required String scope,
    required String itineraryId,
    String? itineraryDetailId,
    required List<ReviewMediaUploadCandidate> files,
  }) {
    return dataSource.createReviewPresignedUrls(
      scope: scope,
      itineraryId: itineraryId,
      itineraryDetailId: itineraryDetailId,
      files: files,
    );
  }

  @override
  Future<void> uploadReviewMediaToR2({
    required ReviewMediaPresignedUrl presignedUrl,
    required String localPath,
    required String contentType,
    required int contentLength,
    void Function(int sent, int total)? onSendProgress,
  }) {
    return dataSource.uploadReviewMediaToR2(
      presignedUrl: presignedUrl,
      file: File(localPath),
      contentType: contentType,
      contentLength: contentLength,
      onSendProgress: onSendProgress,
    );
  }
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/review/data/models/itinerary_review_model.dart';
import 'package:travel_advisor_mobile/features/review/data/models/location_review_model.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_types.dart';

export 'package:travel_advisor_mobile/features/review/domain/entities/review_types.dart';

abstract class ReviewDataSource {
  Future<ReviewCatalog> getReviewCatalog();
  Future<ItineraryReviewModel> getItineraryForReview(
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
    required File file,
    required String contentType,
    required int contentLength,
    void Function(int sent, int total)? onSendProgress,
  });
}

class RemoteReviewDataSource implements ReviewDataSource {
  final DioClient _client;

  RemoteReviewDataSource(this._client);

  @override
  Future<ReviewCatalog> getReviewCatalog() async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/reviews',
      queryParameters: {'tourist_id': touristId, 'status': 'all'},
      options: _client.forceRefreshOptions,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    List<ReviewCatalogItem> parse(String key) =>
        ((data[key] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  ReviewCatalogItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
    return ReviewCatalog(
      pending: parse('pending'),
      reviewed: parse('reviewed'),
    );
  }

  int _parseDayLabel(String label) {
    final normalized = label.toUpperCase().trim();
    final match = RegExp(r'(\d+)').firstMatch(normalized);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  String _formatDateRange(String startDate, String endDate) {
    if (startDate.isEmpty && endDate.isEmpty) {
      return 'Không rõ thời gian';
    }
    if (startDate.isEmpty) {
      return endDate;
    }
    if (endDate.isEmpty) {
      return startDate;
    }
    return '$startDate - $endDate';
  }

  @override
  Future<ItineraryReviewModel> getItineraryForReview(
    String itineraryId, {
    bool forceRefresh = false,
  }) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/itinerary-reviews/$itineraryId/detail',
      queryParameters: {'tourist_id': touristId},
      options: forceRefresh ? _client.forceRefreshOptions : null,
    );

    final data = response.data as Map<String, dynamic>;
    final itinerary =
        (data['itinerary'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final places = (data['places'] as List?) ?? const [];
    return ItineraryReviewModel(
      id: (itinerary['id'] ?? itineraryId).toString(),
      title: (itinerary['title'] ?? 'Lịch trình của bạn').toString(),
      imageUrl: (itinerary['cover_image'] ?? '').toString(),
      dateRange: _formatDateRange(
        (itinerary['start_date'] ?? '').toString(),
        (itinerary['end_date'] ?? '').toString(),
      ),
      status: ((itinerary['status'] ?? 'completed').toString()).toUpperCase(),
      locations: places
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => LocationReviewModel(
              id: (item['itinerary_detail_id'] ?? '').toString(),
              name: (item['place_name'] ?? 'Địa điểm').toString(),
              imageUrl: (item['place_image_url'] ?? '').toString(),
              day: _parseDayLabel((item['day_label'] ?? '').toString()),
              placeId: item['place_id']?.toString(),
              categoryId: item['category_id']?.toString(),
              isVisited: item['is_visited'] == true,
              hasReview: item['has_review'] == true,
              rating: (item['rating'] as num?)?.toDouble(),
              reviewText: item['content']?.toString(),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(),
    );
  }

  @override
  Future<SubmittedReviewData> getSubmittedReview(
    String itineraryId, {
    bool forceRefresh = false,
  }) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/itinerary-reviews/$itineraryId/review-detail',
      queryParameters: {'tourist_id': touristId},
      options: forceRefresh ? _client.forceRefreshOptions : null,
    );
    final data = response.data as Map<String, dynamic>;
    final itinerary = (data['itinerary'] as Map<String, dynamic>?) ?? const {};
    final overall = (data['overall'] as Map<String, dynamic>?) ?? const {};
    final rawPlaces = (data['places'] as List?) ?? const [];

    return SubmittedReviewData(
      itineraryId: (itinerary['id'] ?? itineraryId).toString(),
      itineraryTitle: (itinerary['title'] ?? 'Lịch trình của bạn').toString(),
      destination: itinerary['destination']?.toString(),
      itineraryStatus: itinerary['status']?.toString(),
      coverImage: itinerary['cover_image']?.toString(),
      startDate: (itinerary['start_date'] ?? '').toString(),
      endDate: (itinerary['end_date'] ?? '').toString(),
      overallRating: (overall['rating'] as num?)?.toDouble(),
      overallContent: overall['content']?.toString(),
      overallTags: ((overall['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      overallMediaUrls:
          (overall['media_urls'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      overallReviewedAt: DateTime.tryParse(
        (overall['reviewed_at'] ?? '').toString(),
      ),
      places: rawPlaces.whereType<Map<String, dynamic>>().map((p) {
        return SubmittedPlaceReview(
          itineraryDetailId: (p['itinerary_detail_id'] ?? '').toString(),
          dayLabel: (p['day_label'] ?? 'DAY').toString(),
          placeName: (p['place_name'] ?? 'Địa điểm').toString(),
          placeImageUrl: p['place_image_url']?.toString(),
          rating: (p['rating'] as num?)?.toDouble(),
          content: p['content']?.toString(),
          tags: ((p['tags'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
          mediaUrls:
              (p['media_urls'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
          reviewedAt: DateTime.tryParse((p['reviewed_at'] ?? '').toString()),
        );
      }).toList(),
    );
  }

  @override
  Future<ItineraryReviewSummary> getReviewSummary(String itineraryId) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/itinerary-reviews/$itineraryId/summary',
      queryParameters: {'tourist_id': touristId},
      options: _client.forceRefreshOptions,
    );
    final data = response.data as Map<String, dynamic>;
    return ItineraryReviewSummary(
      hasReview: data['has_review'] == true,
      rating: (data['rating'] as num?)?.toDouble(),
      content: data['content']?.toString(),
    );
  }

  @override
  Future<ItineraryReviewPopupData> getPopupData(String itineraryId) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/itinerary-reviews/popup',
      queryParameters: {'tourist_id': touristId, 'itinerary_id': itineraryId},
    );

    final data = response.data as Map<String, dynamic>;
    final itinerary =
        (data['itinerary'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    return ItineraryReviewPopupData(
      showPopup: data['show_popup'] == true,
      reason: (data['reason'] ?? '').toString(),
      itineraryId: (itinerary['id'] ?? itineraryId).toString(),
      itineraryTitle: (itinerary['title'] ?? 'Lịch trình của bạn').toString(),
    );
  }

  @override
  Future<void> dismissPopup(String itineraryId) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    await _client.dio.post(
      '/itinerary-reviews/popup/dismiss',
      data: {'tourist_id': touristId, 'itinerary_id': itineraryId},
    );
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
    final touristId = await AuthUtils.requireCurrentUserId();

    await _client.dio.post(
      '/itinerary-reviews/$itineraryId/submit',
      data: {
        'tourist_id': touristId,
        if (overallRating != null) 'overall_rating': overallRating.round(),
        if (overallContent != null && overallContent.trim().isNotEmpty)
          'overall_content': overallContent,
        if (overallTags.isNotEmpty) 'tags': overallTags,
        'apply_all_places': applyAllPlaces,
        if (placeReviews.isNotEmpty)
          'place_reviews': placeReviews
              .map(
                (item) => {
                  'itinerary_detail_id': item.itineraryDetailId,
                  'rating': item.rating,
                  if (item.content != null && item.content!.trim().isNotEmpty)
                    'content': item.content,
                  if (item.tags.isNotEmpty) 'tags': item.tags,
                  if (item.media.isNotEmpty)
                    'media': item.media
                        .map(
                          (mediaItem) => {
                            'object_key': mediaItem.objectKey,
                            'media_type': mediaItem.mediaType,
                            'sort_order': mediaItem.sortOrder,
                          },
                        )
                        .toList(),
                },
              )
              .toList(),
        if (media.isNotEmpty)
          'media': media
              .map(
                (item) => {
                  'object_key': item.objectKey,
                  'media_type': item.mediaType,
                  'sort_order': item.sortOrder,
                },
              )
              .toList(),
      },
    );
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
    final normalizedItineraryId = itineraryId?.trim() ?? '';

    await _client.dio.post(
      '/reviews',
      data: {
        'place_id': placeId,
        if (normalizedItineraryId.isNotEmpty)
          'itinerary_id': normalizedItineraryId,
        'rating': rating.round(),
        if (content != null && content.trim().isNotEmpty) 'content': content,
        if (tags.isNotEmpty) 'tags': tags,
        if (images.isNotEmpty) 'images': images,
      },
    );
  }

  @override
  Future<List<ReviewMediaPresignedUrl>> createReviewPresignedUrls({
    required String scope,
    required String itineraryId,
    String? itineraryDetailId,
    required List<ReviewMediaUploadCandidate> files,
  }) async {
    if (files.isEmpty) {
      return const [];
    }

    final normalizedItineraryDetailId = itineraryDetailId?.trim() ?? '';

    final response = await _client.dio.post(
      '/upload/reviews/presigned-urls',
      data: {
        'scope': scope,
        'itinerary_id': itineraryId,
        if (normalizedItineraryDetailId.isNotEmpty)
          'itinerary_detail_id': normalizedItineraryDetailId,
        'files': files
            .map(
              (file) => {
                'file_name': file.fileName,
                'content_type': file.contentType,
                'size': file.size,
                'sort_order': file.sortOrder,
              },
            )
            .toList(),
      },
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ReviewMediaPresignedUrl.fromJson)
        .where((item) => item.uploadUrl.isNotEmpty && item.objectKey.isNotEmpty)
        .toList();
  }

  @override
  Future<void> uploadReviewMediaToR2({
    required ReviewMediaPresignedUrl presignedUrl,
    required File file,
    required String contentType,
    required int contentLength,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final uploadDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(minutes: 2),
      ),
    );

    await uploadDio.put(
      presignedUrl.uploadUrl,
      data: file.openRead(),
      onSendProgress: onSendProgress,
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: contentLength,
        },
      ),
    );
  }
}

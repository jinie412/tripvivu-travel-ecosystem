import 'dart:io';

import 'package:dio/dio.dart';
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/review/data/models/itinerary_review_model.dart';
import 'package:travel_advisor_mobile/features/review/data/models/location_review_model.dart';

class ItineraryReviewPopupData {
  final bool showPopup;
  final String reason;
  final String itineraryId;
  final String itineraryTitle;

  const ItineraryReviewPopupData({
    required this.showPopup,
    required this.reason,
    required this.itineraryId,
    required this.itineraryTitle,
  });
}

class SubmittedPlaceReview {
  final String itineraryDetailId;
  final String dayLabel;
  final String placeName;
  final String? placeImageUrl;
  final double? rating;
  final String? content;
  final List<String> tags;
  final List<String> mediaUrls;
  final DateTime? reviewedAt;

  const SubmittedPlaceReview({
    required this.itineraryDetailId,
    required this.dayLabel,
    required this.placeName,
    this.placeImageUrl,
    this.rating,
    this.content,
    this.tags = const [],
    this.mediaUrls = const [],
    this.reviewedAt,
  });
}

class SubmittedReviewData {
  final String itineraryId;
  final String itineraryTitle;
  final String? destination;
  final String? itineraryStatus;
  final String? coverImage;
  final String startDate;
  final String endDate;
  final double? overallRating;
  final String? overallContent;
  final List<String> overallTags;
  final List<String> overallMediaUrls;
  final DateTime? overallReviewedAt;
  final List<SubmittedPlaceReview> places;

  const SubmittedReviewData({
    required this.itineraryId,
    required this.itineraryTitle,
    this.destination,
    this.itineraryStatus,
    this.coverImage,
    required this.startDate,
    required this.endDate,
    this.overallRating,
    this.overallContent,
    this.overallTags = const [],
    this.overallMediaUrls = const [],
    this.overallReviewedAt,
    required this.places,
  });
}

class ItineraryReviewSummary {
  final bool hasReview;
  final double? rating;
  final String? content;

  const ItineraryReviewSummary({
    required this.hasReview,
    this.rating,
    this.content,
  });
}

class SubmitPlaceReviewInput {
  final String itineraryDetailId;
  final int rating;
  final String? content;
  final List<String> tags;
  final List<SubmitReviewMediaInput> media;

  const SubmitPlaceReviewInput({
    required this.itineraryDetailId,
    required this.rating,
    this.content,
    this.tags = const [],
    this.media = const [],
  });
}

class SubmitReviewMediaInput {
  final String objectKey;
  final String mediaType;
  final int sortOrder;

  const SubmitReviewMediaInput({
    required this.objectKey,
    required this.mediaType,
    required this.sortOrder,
  });
}

class ReviewMediaUploadCandidate {
  final String fileName;
  final String contentType;
  final int size;
  final int sortOrder;

  const ReviewMediaUploadCandidate({
    required this.fileName,
    required this.contentType,
    required this.size,
    required this.sortOrder,
  });
}

class ReviewMediaPresignedUrl {
  final String uploadUrl;
  final String objectKey;
  final String publicUrl;
  final String mediaType;
  final int sortOrder;
  final int expiresInSeconds;

  const ReviewMediaPresignedUrl({
    required this.uploadUrl,
    required this.objectKey,
    required this.publicUrl,
    required this.mediaType,
    required this.sortOrder,
    required this.expiresInSeconds,
  });

  factory ReviewMediaPresignedUrl.fromJson(Map<String, dynamic> json) {
    return ReviewMediaPresignedUrl(
      uploadUrl: (json['upload_url'] ?? '').toString(),
      objectKey: (json['object_key'] ?? '').toString(),
      publicUrl: (json['public_url'] ?? '').toString(),
      mediaType: (json['media_type'] ?? '').toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      expiresInSeconds: (json['expires_in_seconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReviewCatalogItem {
  final String kind;
  final String status;
  final String? reviewId;
  final String itineraryId;
  final String? itineraryDetailId;
  final String? placeId;
  final String title;
  final String? imageUrl;
  final double? rating;
  final String? content;
  final DateTime? reviewedAt;
  final String? itineraryTitle;
  final String? destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? visitDate;
  final List<String> tags;
  final List<String> mediaUrls;
  final String? reviewStatus;
  final String? itineraryStatus;
  final List<ReviewedPlaceItem> placeReviews;

  const ReviewCatalogItem({
    required this.kind,
    required this.status,
    required this.reviewId,
    required this.itineraryId,
    required this.itineraryDetailId,
    required this.placeId,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.content,
    required this.reviewedAt,
    required this.itineraryTitle,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.visitDate,
    required this.tags,
    required this.mediaUrls,
    required this.reviewStatus,
    required this.itineraryStatus,
    required this.placeReviews,
  });

  bool get isItinerary => kind == 'itinerary';
  bool get isReviewed => status == 'reviewed';

  factory ReviewCatalogItem.fromJson(Map<String, dynamic> json) =>
      ReviewCatalogItem(
        kind: (json['kind'] ?? 'place').toString(),
        status: (json['status'] ?? 'pending').toString(),
        reviewId: json['review_id']?.toString(),
        itineraryId: (json['itinerary_id'] ?? '').toString(),
        itineraryDetailId: json['itinerary_detail_id']?.toString(),
        placeId: json['place_id']?.toString(),
        title: (json['title'] ?? 'Đánh giá').toString(),
        imageUrl: json['image_url']?.toString(),
        rating: (json['rating'] as num?)?.toDouble(),
        content: json['content']?.toString(),
        reviewedAt: DateTime.tryParse((json['reviewed_at'] ?? '').toString()),
        itineraryTitle: json['itinerary_title']?.toString(),
        destination: json['destination']?.toString(),
        startDate: DateTime.tryParse((json['start_date'] ?? '').toString()),
        endDate: DateTime.tryParse((json['end_date'] ?? '').toString()),
        visitDate: DateTime.tryParse((json['visit_date'] ?? '').toString()),
        tags: ((json['tags'] as List?) ?? const [])
            .map((item) => item.toString())
            .toList(),
        mediaUrls: ((json['media_urls'] as List?) ?? const [])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList(),
        reviewStatus: json['review_status']?.toString(),
        itineraryStatus: json['itinerary_status']?.toString(),
        placeReviews: ((json['place_reviews'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  ReviewedPlaceItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
      );
}

class ReviewedPlaceItem {
  final String title;
  final String? imageUrl;
  final double rating;
  final String? content;
  final DateTime? visitDate;
  final List<String> tags;
  final List<String> mediaUrls;
  final DateTime? reviewedAt;

  const ReviewedPlaceItem({
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.content,
    required this.visitDate,
    required this.tags,
    required this.mediaUrls,
    required this.reviewedAt,
  });

  factory ReviewedPlaceItem.fromJson(Map<String, dynamic> json) =>
      ReviewedPlaceItem(
        title: (json['place_name'] ?? 'Địa điểm').toString(),
        imageUrl: json['place_image_url']?.toString(),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        content: json['content']?.toString(),
        visitDate: DateTime.tryParse((json['visit_date'] ?? '').toString()),
        tags: ((json['tags'] as List?) ?? const [])
            .map((item) => item.toString())
            .toList(),
        mediaUrls: ((json['media_urls'] as List?) ?? const [])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList(),
        reviewedAt: DateTime.tryParse((json['reviewed_at'] ?? '').toString()),
      );
}

class ReviewCatalog {
  final List<ReviewCatalogItem> pending;
  final List<ReviewCatalogItem> reviewed;
  const ReviewCatalog({required this.pending, required this.reviewed});
}

abstract class ReviewDataSource {
  Future<ReviewCatalog> getReviewCatalog();
  Future<ItineraryReviewModel> getItineraryForReview(String itineraryId);
  Future<SubmittedReviewData> getSubmittedReview(String itineraryId);
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
  Future<ItineraryReviewModel> getItineraryForReview(String itineraryId) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/itinerary-reviews/$itineraryId/detail',
      queryParameters: {'tourist_id': touristId},
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
              rating: (item['rating'] as num?)?.toDouble(),
              reviewText: item['content']?.toString(),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(),
    );
  }

  @override
  Future<SubmittedReviewData> getSubmittedReview(String itineraryId) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/itinerary-reviews/$itineraryId/review-detail',
      queryParameters: {'tourist_id': touristId},
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

    // Để pass qua @IsUUID('4') của NestJS trong chế độ Demo
    final isDemo = AppConfig.kUseMockData;
    final validItineraryId = isDemo
        ? '11111111-1111-4111-a111-111111111111'
        : itineraryId;
    final validTouristId = isDemo
        ? '22222222-2222-4222-a222-222222222222'
        : touristId;

    await _client.dio.post(
      '/itinerary-reviews/$validItineraryId/submit',
      data: {
        'tourist_id': validTouristId,
        if (overallRating != null) 'overall_rating': overallRating.round(),
        if (overallContent != null && overallContent.trim().isNotEmpty)
          'overall_content': overallContent,
        if (overallTags.isNotEmpty) 'tags': overallTags,
        'apply_all_places': applyAllPlaces,
        if (placeReviews.isNotEmpty)
          'place_reviews': placeReviews
              .map(
                (item) => {
                  'itinerary_detail_id': isDemo
                      ? '33333333-3333-4333-a333-333333333333'
                      : item.itineraryDetailId,
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
    final touristId = await AuthUtils.requireCurrentUserId();

    final isDemo = AppConfig.kUseMockData;
    final validTouristId = isDemo ? '22222222-2222-4222-a222-222222222222' : touristId;
    final validPlaceId = isDemo ? '33333333-3333-4333-a333-333333333333' : placeId;

    await _client.dio.post(
      '/reviews',
      data: {
        'tourist_id': validTouristId,
        'place_id': validPlaceId,
        if (itineraryId != null)
          'itinerary_id': isDemo ? '11111111-1111-4111-a111-111111111111' : itineraryId,
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

    final isDemo = AppConfig.kUseMockData;
    final validItineraryId = isDemo
        ? '11111111-1111-4111-a111-111111111111'
        : itineraryId;

    final response = await _client.dio.post(
      '/upload/reviews/presigned-urls',
      data: {
        'scope': scope,
        'itinerary_id': validItineraryId,
        if (itineraryDetailId != null)
          'itinerary_detail_id': isDemo
              ? '33333333-3333-4333-a333-333333333333'
              : itineraryDetailId,
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


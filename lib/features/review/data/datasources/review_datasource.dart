import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
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

class SubmitPlaceReviewInput {
  final String itineraryDetailId;
  final int rating;
  final String? content;
  final List<String> tags;

  const SubmitPlaceReviewInput({
    required this.itineraryDetailId,
    required this.rating,
    this.content,
    this.tags = const [],
  });
}

abstract class ReviewDataSource {
  Future<ItineraryReviewModel> getItineraryForReview(String itineraryId);
  Future<ItineraryReviewPopupData> getPopupData(String itineraryId);
  Future<void> dismissPopup(String itineraryId);
  Future<void> submitItineraryReview({
    required String itineraryId,
    double? overallRating,
    String? overallContent,
    bool applyAllPlaces = false,
    List<SubmitPlaceReviewInput> placeReviews = const [],
    List<String> mediaUrls = const [],
  });
}

class RemoteReviewDataSource implements ReviewDataSource {
  final DioClient _client;

  RemoteReviewDataSource(this._client);

  String _requireTouristId() {
    final touristId = dotenv.env['EXPLORE_TOURIST_ID']?.trim();
    if (touristId == null || touristId.isEmpty) {
      throw Exception('EXPLORE_TOURIST_ID not configured in .env');
    }
    return touristId;
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
    final touristId = _requireTouristId();
    final response = await _client.dio.get(
      '/itinerary-reviews/$itineraryId/detail',
      queryParameters: {'tourist_id': touristId},
    );

    final data = response.data as Map<String, dynamic>;
    final itinerary =
        (data['itinerary'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
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
              rating: (item['rating'] as num?)?.toDouble(),
              reviewText: item['content']?.toString(),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(),
    );
  }

  @override
  Future<ItineraryReviewPopupData> getPopupData(String itineraryId) async {
    final touristId = _requireTouristId();
    final response = await _client.dio.get(
      '/itinerary-reviews/popup',
      queryParameters: {
        'tourist_id': touristId,
        'itinerary_id': itineraryId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final itinerary =
        (data['itinerary'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return ItineraryReviewPopupData(
      showPopup: data['show_popup'] == true,
      reason: (data['reason'] ?? '').toString(),
      itineraryId: (itinerary['id'] ?? itineraryId).toString(),
      itineraryTitle: (itinerary['title'] ?? 'Lịch trình của bạn').toString(),
    );
  }

  @override
  Future<void> dismissPopup(String itineraryId) async {
    final touristId = _requireTouristId();
    await _client.dio.post(
      '/itinerary-reviews/popup/dismiss',
      data: {
        'tourist_id': touristId,
        'itinerary_id': itineraryId,
      },
    );
  }

  @override
  Future<void> submitItineraryReview({
    required String itineraryId,
    double? overallRating,
    String? overallContent,
    bool applyAllPlaces = false,
    List<SubmitPlaceReviewInput> placeReviews = const [],
    List<String> mediaUrls = const [],
  }) async {
    final touristId = _requireTouristId();
    await _client.dio.post(
      '/itinerary-reviews/$itineraryId/submit',
      data: {
        'tourist_id': touristId,
        if (overallRating != null) 'overall_rating': overallRating.round(),
        if (overallContent != null && overallContent.trim().isNotEmpty)
          'overall_content': overallContent,
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
                },
              )
              .toList(),
        if (mediaUrls.isNotEmpty) 'media_urls': mediaUrls,
      },
    );
  }
}
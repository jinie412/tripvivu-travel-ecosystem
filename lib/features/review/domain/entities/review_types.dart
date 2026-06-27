/// Shared types for the review feature.
/// Domain-level DTOs used by the repository interface, cubit, and UI.
library;

// ── Popup ─────────────────────────────────────────────────────────────────

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

// ── Submitted review (read) ───────────────────────────────────────────────

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

// ── Submission (write) ────────────────────────────────────────────────────

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

// ── Media upload ──────────────────────────────────────────────────────────

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

// ── Review catalog ────────────────────────────────────────────────────────

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

class ReviewCatalog {
  final List<ReviewCatalogItem> pending;
  final List<ReviewCatalogItem> reviewed;
  const ReviewCatalog({required this.pending, required this.reviewed});
}

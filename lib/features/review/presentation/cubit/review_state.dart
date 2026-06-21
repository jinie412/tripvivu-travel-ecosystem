import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_media_item.dart';

abstract class ReviewState {}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewLoaded extends ReviewState {
  final ItineraryReviewEntity itinerary;
  final int selectedDay;
  final double generalRating;
  final String generalComment;
  final List<String> generalTags;
  final bool applyToAllLocations;
  final List<ReviewMediaItem> itineraryMedia;
  final Map<String, List<ReviewMediaItem>> locationMediaByDetailId;
  final Map<String, double?> locationRatingsBeforeApplyAll;
  final bool isSubmitting;

  ReviewLoaded({
    required this.itinerary,
    this.selectedDay = 0,
    this.generalRating = 0.0,
    this.generalComment = '',
    this.generalTags = const [],
    this.applyToAllLocations = true,
    this.itineraryMedia = const [],
    this.locationMediaByDetailId = const {},
    this.locationRatingsBeforeApplyAll = const {},
    this.isSubmitting = false,
  });

  ReviewLoaded copyWith({
    ItineraryReviewEntity? itinerary,
    int? selectedDay,
    double? generalRating,
    String? generalComment,
    List<String>? generalTags,
    bool? applyToAllLocations,
    List<ReviewMediaItem>? itineraryMedia,
    Map<String, List<ReviewMediaItem>>? locationMediaByDetailId,
    Map<String, double?>? locationRatingsBeforeApplyAll,
    bool? isSubmitting,
  }) {
    return ReviewLoaded(
      itinerary: itinerary ?? this.itinerary,
      selectedDay: selectedDay ?? this.selectedDay,
      generalRating: generalRating ?? this.generalRating,
      generalComment: generalComment ?? this.generalComment,
      generalTags: generalTags ?? this.generalTags,
      applyToAllLocations: applyToAllLocations ?? this.applyToAllLocations,
      itineraryMedia: itineraryMedia ?? this.itineraryMedia,
      locationMediaByDetailId:
          locationMediaByDetailId ?? this.locationMediaByDetailId,
      locationRatingsBeforeApplyAll:
          locationRatingsBeforeApplyAll ?? this.locationRatingsBeforeApplyAll,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ReviewError extends ReviewState {
  final String message;

  ReviewError(this.message);
}

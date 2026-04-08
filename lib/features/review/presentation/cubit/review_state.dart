import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';

abstract class ReviewState {}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewLoaded extends ReviewState {
  final ItineraryReviewEntity itinerary;
  final int selectedDay;
  final double generalRating;
  final String generalComment;
  final bool applyToAllLocations;
  final List<String> mediaPaths;
  final bool isSubmitting;

  ReviewLoaded({
    required this.itinerary,
    this.selectedDay = 0,
    this.generalRating = 0.0,
    this.generalComment = '',
    this.applyToAllLocations = true,
    this.mediaPaths = const [],
    this.isSubmitting = false,
  });

  ReviewLoaded copyWith({
    ItineraryReviewEntity? itinerary,
    int? selectedDay,
    double? generalRating,
    String? generalComment,
    bool? applyToAllLocations,
    List<String>? mediaPaths,
    bool? isSubmitting,
  }) {
    return ReviewLoaded(
      itinerary: itinerary ?? this.itinerary,
      selectedDay: selectedDay ?? this.selectedDay,
      generalRating: generalRating ?? this.generalRating,
      generalComment: generalComment ?? this.generalComment,
      applyToAllLocations: applyToAllLocations ?? this.applyToAllLocations,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ReviewError extends ReviewState {
  final String message;

  ReviewError(this.message);
}
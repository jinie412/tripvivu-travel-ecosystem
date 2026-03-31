import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';

abstract class ReviewState {}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewLoaded extends ReviewState {
  final ItineraryReviewEntity itinerary;
  final int selectedDay;
  final double generalRating;
  final bool applyToAllLocations;
  final List<String> mediaPaths;

  ReviewLoaded({
    required this.itinerary,
    this.selectedDay = 0,
    this.generalRating = 0.0,
    this.applyToAllLocations = true,
    this.mediaPaths = const [],
  });

  ReviewLoaded copyWith({
    ItineraryReviewEntity? itinerary,
    int? selectedDay,
    double? generalRating,
    bool? applyToAllLocations,
    List<String>? mediaPaths,
  }) {
    return ReviewLoaded(
      itinerary: itinerary ?? this.itinerary,
      selectedDay: selectedDay ?? this.selectedDay,
      generalRating: generalRating ?? this.generalRating,
      applyToAllLocations: applyToAllLocations ?? this.applyToAllLocations,
      mediaPaths: mediaPaths ?? this.mediaPaths,
    );
  }
}

class ReviewError extends ReviewState {
  final String message;

  ReviewError(this.message);
}
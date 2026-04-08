import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'review_state.dart';

import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/domain/usecases/get_itinerary_for_review_usecase.dart';

class ReviewCubit extends Cubit<ReviewState> {
  final GetItineraryForReviewUseCase getItineraryForReview;
  final ReviewRepository reviewRepository;

  ReviewCubit({
    required this.getItineraryForReview,
    required this.reviewRepository,
  }) : super(ReviewInitial());

  Future<void> loadReviewData(String itineraryId) async {
    emit(ReviewLoading());
    try {
      final itinerary = await getItineraryForReview(itineraryId);
      emit(ReviewLoaded(itinerary: itinerary));
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  void filterByDay(int day) {
    if (state is ReviewLoaded) {
      emit((state as ReviewLoaded).copyWith(selectedDay: day));
    }
  }

  void setGeneralRating(double rating) {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      var newItinerary = currentState.itinerary;
      
      if (currentState.applyToAllLocations) {
        final newLocations = newItinerary.locations.map((loc) {
          return loc.copyWith(rating: rating);
        }).toList();
        newItinerary = newItinerary.copyWith(locations: newLocations);
      }
      
      emit(currentState.copyWith(
        generalRating: rating,
        itinerary: newItinerary,
      ));
    }
  }

  void setGeneralComment(String comment) {
    if (state is ReviewLoaded) {
      emit((state as ReviewLoaded).copyWith(generalComment: comment));
    }
  }

  void toggleApplyToAll(bool value) {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      
      var newItinerary = currentState.itinerary;
      if (value) {
        final newLocations = newItinerary.locations.map((loc) {
          return loc.copyWith(rating: currentState.generalRating);
        }).toList();
        newItinerary = newItinerary.copyWith(locations: newLocations);
      }
      
      emit(currentState.copyWith(
        applyToAllLocations: value,
        itinerary: newItinerary,
      ));
    }
  }

  void setLocationRating(String locationId, double rating) {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      final newLocations = currentState.itinerary.locations.map((loc) {
        if (loc.id == locationId) {
          return loc.copyWith(rating: rating);
        }
        return loc;
      }).toList();
      
      final newItinerary = currentState.itinerary.copyWith(locations: newLocations);
      
      emit(currentState.copyWith(
        itinerary: newItinerary,
        applyToAllLocations: false,
      ));
    }
  }

  void updateLocationReviewDetails({
    required String locationId,
    double? rating,
    String? reviewText,
    List<String>? reviewTags,
    List<String>? mediaPaths,
  }) {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      final newLocations = currentState.itinerary.locations.map((loc) {
        if (loc.id == locationId) {
          return loc.copyWith(
            rating: rating ?? loc.rating,
            reviewText: reviewText ?? loc.reviewText,
            reviewTags: reviewTags ?? loc.reviewTags,
            mediaPaths: mediaPaths ?? loc.mediaPaths,
          );
        }
        return loc;
      }).toList();

      final newItinerary = currentState.itinerary.copyWith(locations: newLocations);

      emit(currentState.copyWith(
        itinerary: newItinerary,
        applyToAllLocations: false,
      ));
    }
  }

  Future<void> addMedia() async {
    if (state is ReviewLoaded) {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();
      
      if (pickedFiles.isNotEmpty) {
        final currentState = state as ReviewLoaded;
        final newMedia = List<String>.from(currentState.mediaPaths);
        newMedia.addAll(pickedFiles.map((f) => f.path));
        emit(currentState.copyWith(mediaPaths: newMedia));
      }
    }
  }

  void removeMedia(String path) {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      final newMedia = List<String>.from(currentState.mediaPaths)..remove(path);
      emit(currentState.copyWith(mediaPaths: newMedia));
    }
  }

  void clearAllMedia() {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      emit(currentState.copyWith(mediaPaths: []));
    }
  }

  Future<void> submitReview(String itineraryId) async {
    if (state is! ReviewLoaded) {
      return;
    }

    final currentState = state as ReviewLoaded;
    emit(currentState.copyWith(isSubmitting: true));

    try {
      final placeReviews = currentState.itinerary.locations
          .where((loc) => loc.rating != null)
          .map(
            (loc) => SubmitPlaceReviewInput(
              itineraryDetailId: loc.id,
              rating: loc.rating!.round(),
              content: loc.reviewText,
              tags: loc.reviewTags ?? const [],
            ),
          )
          .toList();

      await reviewRepository.submitItineraryReview(
        itineraryId: itineraryId,
        overallRating:
            currentState.generalRating > 0 ? currentState.generalRating : null,
        overallContent: currentState.generalComment,
        applyAllPlaces: currentState.applyToAllLocations,
        placeReviews: placeReviews,
        mediaUrls: currentState.mediaPaths,
      );

      emit(currentState.copyWith(isSubmitting: false));
    } catch (_) {
      emit(currentState.copyWith(isSubmitting: false));
      rethrow;
    }
  }
}
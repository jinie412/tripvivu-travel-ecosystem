import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/usecases/get_itinerary_for_review_usecase.dart';
import 'review_state.dart';

class ReviewCubit extends Cubit<ReviewState> {
  final GetItineraryForReviewUseCase getItineraryForReview;

  ReviewCubit({required this.getItineraryForReview}) : super(ReviewInitial());

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
}

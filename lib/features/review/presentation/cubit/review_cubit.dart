import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'review_state.dart';

import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/location_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/domain/usecases/get_itinerary_for_review_usecase.dart';
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/core/utils/demo_review_store.dart';

class ReviewCubit extends Cubit<ReviewState> {
  final GetItineraryForReviewUseCase getItineraryForReview;
  final ReviewRepository reviewRepository;

  ReviewCubit({
    required this.getItineraryForReview,
    required this.reviewRepository,
  }) : super(ReviewInitial());

  /// 🔧 CHẾ ĐỘ DEMO: Set true để bỏ qua lỗi Backend và dùng dữ liệu mẫu
  static const bool kDemoMode = AppConfig.kUseMockData;

  Future<void> loadReviewData(String itineraryId) async {
    emit(ReviewLoading());
    
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final itinerary = _generateDemoData();
      final generalRating = DemoReviewStore.itineraryOverallRatings[itineraryId] ?? 0.0;
      final generalComment = DemoReviewStore.itineraryOverallComments[itineraryId] ?? '';
      
      emit(ReviewLoaded(
        itinerary: itinerary,
        generalRating: generalRating,
        generalComment: generalComment,
      ));
      return;
    }

    try {
      final itinerary = await getItineraryForReview(itineraryId);
      emit(ReviewLoaded(itinerary: itinerary));
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  ItineraryReviewEntity _generateDemoData() {
    // Generate data that matches ItineraryCubit's mock structure
    final List<String> day1Ids = ['mock_1_1', 'mock_1_2', 'mock_1_3', 'mock_1_4', 'mock_1_5'];
    final List<String> day2Ids = ['mock_2_1', 'mock_2_2', 'mock_2_3'];
    final List<String> day3Ids = ['mock_3_1', 'mock_3_2'];
    final allIds = [...day1Ids, ...day2Ids, ...day3Ids];

    final locations = allIds.asMap().entries.map((entry) {
      final locId = entry.value;
      final index = entry.key;
      final storedRating = DemoReviewStore.getLocationRating(locId);
      final storedComment = DemoReviewStore.userComments[locId];
      
      return LocationReviewEntity(
        id: locId,
        name: index == 0 ? 'Dinh Độc Lập' : index == 1 ? 'Nhà thờ Đức Bà' : 'Địa điểm ${index + 1}',
        imageUrl: 'https://images.unsplash.com/photo-1559506825-f933e38714eb?w=100&q=80',
        day: index < 5 ? 1 : index < 8 ? 2 : 3,
        isVisited: true,
        rating: storedRating, // Priority to user rating
      );
    }).toList();

    return ItineraryReviewEntity(
      id: 'mock_ongoing',
      title: 'Phú Quốc Hè 2024',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
      dateRange: '15/06 - 18/06/2024',
      status: 'PLANNING',
      locations: locations,
    );
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
      
      // Persist to DemoStore immediately for sync with other screens
      if (kDemoMode) {
        DemoReviewStore.saveLocationRating(locationId, rating);
      }

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
      if (kDemoMode) {
        await Future.delayed(const Duration(seconds: 1));
        
        // Save to DemoStore for persistence across screens
        DemoReviewStore.saveItineraryReview(
          itineraryId, 
          currentState.generalRating, 
          comment: currentState.generalComment
        );
        
        for (var loc in currentState.itinerary.locations) {
          if (loc.rating != null) {
            DemoReviewStore.saveLocationRating(loc.id, loc.rating!, comment: loc.reviewText);
          }
        }

        // TẠM THỜI COMMENT DÒNG RETURN ĐỂ ÉP GỌI XUỐNG BACKEND THẬT DÙ ĐANG Ở CHẾ ĐỘ DEMO
        // emit(currentState.copyWith(isSubmitting: false));
        // return;
      }

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
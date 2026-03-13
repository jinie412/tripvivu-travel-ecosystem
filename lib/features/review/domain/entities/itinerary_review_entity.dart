import 'package:freezed_annotation/freezed_annotation.dart';
import 'location_review_entity.dart';

part 'itinerary_review_entity.freezed.dart';

@freezed
class ItineraryReviewEntity with _$ItineraryReviewEntity {
  const factory ItineraryReviewEntity({
    required String id,
    required String title,
    required String imageUrl,
    required String dateRange,
    required String status,
    required List<LocationReviewEntity> locations,
  }) = _ItineraryReviewEntity;
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'place_food_item_entity.dart';
import 'place_entity.dart';
import 'place_review_entity.dart';

part 'place_detail_entity.freezed.dart';

@freezed
class PlaceDetailEntity with _$PlaceDetailEntity {
  const factory PlaceDetailEntity({
    required String id,
    required String name,
    required String address,
    required String district,
    required String city,
    required double rating,
    required int totalReviews,
    String? typeName,
    @Default([]) List<String> vibes,
    @Default([]) List<String> categories,
    @Default([]) List<String> images,
    required String description,
    String? openingHours,
    String? closingHours,
    String? openHourCompressed,
    String? phone,
    double? minimumHotelPrice,
    @Default([]) List<PlaceFoodItemEntity> foodItems,
    @Default([]) List<PlaceReviewEntity> reviews,
    @Default({}) Map<int, int> reviewBreakdown,
    @Default([]) List<PlaceEntity> relatedPlaces,
    @Default(false) bool isFavorite,
    double? latitude,
    double? longitude,
  }) = _PlaceDetailEntity;
}

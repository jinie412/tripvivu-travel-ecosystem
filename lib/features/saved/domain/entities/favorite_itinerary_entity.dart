import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_itinerary_entity.freezed.dart';

@freezed
class FavoriteItineraryEntity with _$FavoriteItineraryEntity {
  const factory FavoriteItineraryEntity({
    required String id,
    required String title,
    required String location,
    required int days,
    required int participantCount,
    required String status,
    @Default(0) double rating,
    @Default(0) int reviewCount,
    String? image,
    @Default(<String>[]) List<String> imageGallery,
  }) = _FavoriteItineraryEntity;
}

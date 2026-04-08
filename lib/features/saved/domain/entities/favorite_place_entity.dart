import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_place_entity.freezed.dart';

@freezed
class FavoritePlaceEntity with _$FavoritePlaceEntity {
  const factory FavoritePlaceEntity({
    required String id,
    required String name,
    required String city,
    required String image,
    required double rating,
    required int reviewCount,
  }) = _FavoritePlaceEntity;
}

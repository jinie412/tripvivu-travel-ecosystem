import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_entity.freezed.dart';

@freezed
class PlaceEntity with _$PlaceEntity {
  const factory PlaceEntity({
    required String id,
    required String name,
    required String imageUrl,
    required double rating,
    required String district,
    required String city,
  }) = _PlaceEntity;
}
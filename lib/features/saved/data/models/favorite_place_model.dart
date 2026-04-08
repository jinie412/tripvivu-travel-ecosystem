import 'package:json_annotation/json_annotation.dart';
import 'package:travel_advisor_mobile/features/saved/domain/entities/favorite_place_entity.dart';

part 'favorite_place_model.g.dart';

@JsonSerializable()
class FavoritePlaceModel {
  final String id;
  final String name;
  final String city;
  final String image;
  final double rating;
  @JsonKey(name: 'review_count')
  final int reviewCount;

  const FavoritePlaceModel({
    required this.id,
    required this.name,
    required this.city,
    required this.image,
    required this.rating,
    required this.reviewCount,
  });

  factory FavoritePlaceModel.fromJson(Map<String, dynamic> json) =>
      _$FavoritePlaceModelFromJson(json);

  Map<String, dynamic> toJson() => _$FavoritePlaceModelToJson(this);

  FavoritePlaceEntity toEntity() => FavoritePlaceEntity(
    id: id,
    name: name,
    city: city,
    image: image,
    rating: rating,
    reviewCount: reviewCount,
  );
}

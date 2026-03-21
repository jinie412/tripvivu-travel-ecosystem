import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/place_entity.dart';

part 'place_model.g.dart';

@JsonSerializable()
class PlaceModel {
  final String id;
  final String name;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  final double rating;
  final String district;
  final String city;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.district,
    required this.city,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) => _$PlaceModelFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceModelToJson(this);

  PlaceEntity toEntity() => PlaceEntity(
    id: id,
    name: name,
    imageUrl: imageUrl,
    rating: rating,
    district: district,
    city: city,
  );
}

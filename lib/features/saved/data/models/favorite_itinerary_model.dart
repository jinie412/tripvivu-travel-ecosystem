import 'package:json_annotation/json_annotation.dart';
import 'package:travel_advisor_mobile/features/saved/domain/entities/favorite_itinerary_entity.dart';

part 'favorite_itinerary_model.g.dart';

@JsonSerializable()
class FavoriteItineraryModel {
  final String id;
  final String title;
  final String location;
  final int days;
  @JsonKey(name: 'participant_count')
  final int participantCount;
  final String status;
  final String? image;
  @JsonKey(name: 'image_gallery', defaultValue: <String>[])
  final List<String> imageGallery;

  const FavoriteItineraryModel({
    required this.id,
    required this.title,
    required this.location,
    required this.days,
    required this.participantCount,
    required this.status,
    this.image,
    this.imageGallery = const <String>[],
  });

  factory FavoriteItineraryModel.fromJson(Map<String, dynamic> json) =>
      _$FavoriteItineraryModelFromJson(json);

  Map<String, dynamic> toJson() => _$FavoriteItineraryModelToJson(this);

  FavoriteItineraryEntity toEntity() => FavoriteItineraryEntity(
    id: id,
    title: title,
    location: location,
    days: days,
    participantCount: participantCount,
    status: status,
    image: image,
    imageGallery: imageGallery,
  );
}

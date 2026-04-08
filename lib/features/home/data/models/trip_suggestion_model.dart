import 'package:json_annotation/json_annotation.dart';

import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';

part 'trip_suggestion_model.g.dart';

@JsonSerializable()
class TripSuggestionModel {
  final String id;
  final String title;
  final String days;
  final String location;
  final String views;
  final String likes;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'placeholder_color')
  final int placeholderColor;

  const TripSuggestionModel({
    required this.id,
    required this.title,
    required this.days,
    required this.location,
    required this.views,
    required this.likes,
    this.imageUrl,
    this.placeholderColor = 0xFF4A90D9,
  });

  factory TripSuggestionModel.fromJson(Map<String, dynamic> json) =>
      _$TripSuggestionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TripSuggestionModelToJson(this);

  TripSuggestion toEntity() => TripSuggestion(
        id: id,
        title: title,
        days: days,
        location: location,
        views: views,
        likes: likes,
        imageUrl: imageUrl,
        placeholderColor: placeholderColor,
      );
}
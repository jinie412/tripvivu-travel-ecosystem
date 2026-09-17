import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';

import 'package:json_annotation/json_annotation.dart';

part 'trip_suggestion_model.g.dart';

@JsonSerializable()
class TripSuggestionModel {
  final String id;
  final String title;
  final String authorName;
  final String authorAvatar;
  final String days;
  final String location;
  final String views;
  final String likes;
  final String? imageUrl;
  @JsonKey(name: 'image_gallery', defaultValue: <String>[])
  final List<String> imageGallery;
  final int placeholderColor;
  final bool isFavorite;
  @JsonKey(name: 'favorite_count', defaultValue: 0)
  final int favoriteCount;
  @JsonKey(name: 'average_rating', defaultValue: 0.0)
  final double rating;
  @JsonKey(name: 'trip_intent', defaultValue: '')
  final String travelType;

  const TripSuggestionModel({
    required this.id,
    required this.title,
    this.authorName = 'Traveler',
    this.authorAvatar = '',
    required this.days,
    required this.location,
    required this.views,
    required this.likes,
    this.imageUrl,
    this.imageGallery = const <String>[],
    this.placeholderColor = 0xFF4A90D9,
    this.isFavorite = false,
    this.favoriteCount = 0,
    this.rating = 0.0,
    this.travelType = '',
  });

  TripSuggestion toEntity() => TripSuggestion(
        id: id,
        title: title,
        authorName: authorName,
        authorAvatar: authorAvatar,
        days: days,
        location: location,
        views: views,
        likes: favoriteCount > 0 ? favoriteCount.toString() : likes,
        favoriteCount: favoriteCount,
        rating: rating,
        travelType: travelType,
        imageUrl: imageUrl,
        imageUrls: imageGallery,
        placeholderColor: placeholderColor,
        isFavorite: isFavorite,
      );
}

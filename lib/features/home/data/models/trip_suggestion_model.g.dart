// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_suggestion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripSuggestionModel _$TripSuggestionModelFromJson(Map<String, dynamic> json) =>
    TripSuggestionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      authorName: json['authorName'] as String? ?? 'Traveler',
      authorAvatar: json['authorAvatar'] as String? ?? '',
      days: json['days'] as String,
      location: json['location'] as String,
      views: json['views'] as String,
      likes: json['likes'] as String,
      imageUrl: json['imageUrl'] as String?,
      imageGallery:
          (json['image_gallery'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      placeholderColor:
          (json['placeholderColor'] as num?)?.toInt() ?? 0xFF4A90D9,
    );

Map<String, dynamic> _$TripSuggestionModelToJson(
  TripSuggestionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'authorName': instance.authorName,
  'authorAvatar': instance.authorAvatar,
  'days': instance.days,
  'location': instance.location,
  'views': instance.views,
  'likes': instance.likes,
  'imageUrl': instance.imageUrl,
  'image_gallery': instance.imageGallery,
  'placeholderColor': instance.placeholderColor,
};

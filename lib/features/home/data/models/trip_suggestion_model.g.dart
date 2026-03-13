// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_suggestion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripSuggestionModel _$TripSuggestionModelFromJson(Map<String, dynamic> json) =>
    TripSuggestionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      days: json['days'] as String,
      location: json['location'] as String,
      views: json['views'] as String,
      likes: json['likes'] as String,
      imageUrl: json['image_url'] as String?,
      placeholderColor:
          (json['placeholder_color'] as num?)?.toInt() ?? 0xFF4A90D9,
    );

Map<String, dynamic> _$TripSuggestionModelToJson(
  TripSuggestionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'days': instance.days,
  'location': instance.location,
  'views': instance.views,
  'likes': instance.likes,
  'image_url': instance.imageUrl,
  'placeholder_color': instance.placeholderColor,
};

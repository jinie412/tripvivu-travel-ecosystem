// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceReviewModel _$PlaceReviewModelFromJson(Map<String, dynamic> json) =>
    PlaceReviewModel(
      id: json['id'] as String,
      userName: json['user_name'] as String,
      userAvatar: json['user_avatar'] as String,
      rating: (json['rating'] as num).toDouble(),
      timeAgo: json['time_ago'] as String,
      reviewText: json['review_text'] as String,
      reviewImages:
          (json['review_images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PlaceReviewModelToJson(PlaceReviewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_name': instance.userName,
      'user_avatar': instance.userAvatar,
      'rating': instance.rating,
      'time_ago': instance.timeAgo,
      'review_text': instance.reviewText,
      'review_images': instance.reviewImages,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LocationReviewModelImpl _$$LocationReviewModelImplFromJson(
  Map<String, dynamic> json,
) => _$LocationReviewModelImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  imageUrl: json['imageUrl'] as String,
  day: (json['day'] as num).toInt(),
  rating: (json['rating'] as num?)?.toDouble(),
  reviewText: json['reviewText'] as String?,
);

Map<String, dynamic> _$$LocationReviewModelImplToJson(
  _$LocationReviewModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'imageUrl': instance.imageUrl,
  'day': instance.day,
  'rating': instance.rating,
  'reviewText': instance.reviewText,
};

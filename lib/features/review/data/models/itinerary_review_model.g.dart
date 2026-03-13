// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItineraryReviewModelImpl _$$ItineraryReviewModelImplFromJson(
  Map<String, dynamic> json,
) => _$ItineraryReviewModelImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  imageUrl: json['imageUrl'] as String,
  dateRange: json['dateRange'] as String,
  status: json['status'] as String,
  locations: (json['locations'] as List<dynamic>)
      .map((e) => LocationReviewModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$ItineraryReviewModelImplToJson(
  _$ItineraryReviewModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'imageUrl': instance.imageUrl,
  'dateRange': instance.dateRange,
  'status': instance.status,
  'locations': instance.locations,
};

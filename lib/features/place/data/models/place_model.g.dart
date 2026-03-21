// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceModel _$PlaceModelFromJson(Map<String, dynamic> json) => PlaceModel(
  id: json['id'] as String,
  name: json['name'] as String,
  imageUrl: json['image_url'] as String,
  rating: (json['rating'] as num).toDouble(),
  district: json['district'] as String,
  city: json['city'] as String,
);

Map<String, dynamic> _$PlaceModelToJson(PlaceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image_url': instance.imageUrl,
      'rating': instance.rating,
      'district': instance.district,
      'city': instance.city,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceDetailModel _$PlaceDetailModelFromJson(Map<String, dynamic> json) =>
    PlaceDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      district: json['district'] as String,
      city: json['city'] as String,
      rating: (json['rating'] as num).toDouble(),
      totalReviews: (json['total_reviews'] as num).toInt(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      description: json['description'] as String,
      openingHours: json['opening_hours'] as String,
      closingHours: json['closing_hours'] as String,
      phone: json['phone'] as String,
      reviews:
          (json['reviews'] as List<dynamic>?)
              ?.map((e) => PlaceReviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      relatedPlaces:
          (json['related_places'] as List<dynamic>?)
              ?.map((e) => PlaceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isFavorite: json['is_favorite'] as bool? ?? false,
    );

Map<String, dynamic> _$PlaceDetailModelToJson(PlaceDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'district': instance.district,
      'city': instance.city,
      'rating': instance.rating,
      'total_reviews': instance.totalReviews,
      'tags': instance.tags,
      'images': instance.images,
      'description': instance.description,
      'opening_hours': instance.openingHours,
      'closing_hours': instance.closingHours,
      'phone': instance.phone,
      'reviews': instance.reviews,
      'related_places': instance.relatedPlaces,
      'is_favorite': instance.isFavorite,
    };

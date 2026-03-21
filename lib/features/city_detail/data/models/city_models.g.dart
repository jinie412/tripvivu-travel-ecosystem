// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CityItineraryModelImpl _$$CityItineraryModelImplFromJson(
  Map<String, dynamic> json,
) => _$CityItineraryModelImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  authorName: json['authorName'] as String,
  authorAvatar: json['authorAvatar'] as String,
  imageUrl: json['imageUrl'] as String,
  duration: json['duration'] as String,
  views: json['views'] as String,
  likes: json['likes'] as String,
);

Map<String, dynamic> _$$CityItineraryModelImplToJson(
  _$CityItineraryModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'authorName': instance.authorName,
  'authorAvatar': instance.authorAvatar,
  'imageUrl': instance.imageUrl,
  'duration': instance.duration,
  'views': instance.views,
  'likes': instance.likes,
};

_$CityActivityModelImpl _$$CityActivityModelImplFromJson(
  Map<String, dynamic> json,
) => _$CityActivityModelImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  imageUrl: json['imageUrl'] as String,
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
  address: json['address'] as String? ?? '',
  status: json['status'] as String? ?? '',
  isFavorite: json['isFavorite'] as bool? ?? false,
);

Map<String, dynamic> _$$CityActivityModelImplToJson(
  _$CityActivityModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'imageUrl': instance.imageUrl,
  'rating': instance.rating,
  'reviewCount': instance.reviewCount,
  'address': instance.address,
  'status': instance.status,
  'isFavorite': instance.isFavorite,
};

_$CityRestaurantModelImpl _$$CityRestaurantModelImplFromJson(
  Map<String, dynamic> json,
) => _$CityRestaurantModelImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  imageUrl: json['imageUrl'] as String,
  rating: (json['rating'] as num).toDouble(),
  reviewCount: (json['reviewCount'] as num).toInt(),
  address: json['address'] as String? ?? '',
  status: json['status'] as String? ?? '',
  isFavorite: json['isFavorite'] as bool? ?? false,
);

Map<String, dynamic> _$$CityRestaurantModelImplToJson(
  _$CityRestaurantModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'imageUrl': instance.imageUrl,
  'rating': instance.rating,
  'reviewCount': instance.reviewCount,
  'address': instance.address,
  'status': instance.status,
  'isFavorite': instance.isFavorite,
};

_$CityHotelModelImpl _$$CityHotelModelImplFromJson(Map<String, dynamic> json) =>
    _$CityHotelModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['reviewCount'] as num).toInt(),
      price: json['price'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );

Map<String, dynamic> _$$CityHotelModelImplToJson(
  _$CityHotelModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'imageUrl': instance.imageUrl,
  'rating': instance.rating,
  'reviewCount': instance.reviewCount,
  'price': instance.price,
  'isFavorite': instance.isFavorite,
};

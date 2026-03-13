// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hotel_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HotelModel _$HotelModelFromJson(Map<String, dynamic> json) => HotelModel(
  id: json['id'] as String,
  name: json['name'] as String,
  rating: (json['rating'] as num).toDouble(),
  price: json['price'] as String,
  priceUnit: json['price_unit'] as String? ?? '1 đêm',
  imageUrl: json['image_url'] as String?,
  placeholderColor: (json['placeholder_color'] as num?)?.toInt() ?? 0xFFD4C5B0,
);

Map<String, dynamic> _$HotelModelToJson(HotelModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'rating': instance.rating,
      'price': instance.price,
      'price_unit': instance.priceUnit,
      'image_url': instance.imageUrl,
      'placeholder_color': instance.placeholderColor,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItineraryActivityModel _$ItineraryActivityModelFromJson(
  Map<String, dynamic> json,
) => ItineraryActivityModel(
  id: json['id'] as String,
  title: json['title'] as String,
  startTime: json['start_time'] as String,
  endTime: json['end_time'] as String,
  locationName: json['location_name'] as String,
  address: json['address'] as String,
  imageUrl: json['image_url'] as String,
  price: (json['price'] as num?)?.toDouble() ?? 0,
  currency: json['currency'] as String? ?? 'VNĐ',
  transportInfo: json['transport_info'] as String?,
  isFree: json['is_free'] as bool? ?? false,
  category: json['category'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  status: json['status'] as String?,
);

Map<String, dynamic> _$ItineraryActivityModelToJson(
  ItineraryActivityModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'location_name': instance.locationName,
  'address': instance.address,
  'image_url': instance.imageUrl,
  'price': instance.price,
  'currency': instance.currency,
  'transport_info': instance.transportInfo,
  'is_free': instance.isFree,
  'category': instance.category,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'status': instance.status,
};

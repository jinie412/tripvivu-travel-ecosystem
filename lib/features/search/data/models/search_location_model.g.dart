// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchLocationModelImpl _$$SearchLocationModelImplFromJson(
  Map<String, dynamic> json,
) => _$SearchLocationModelImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  imageUrl: json['imageUrl'] as String,
  type: json['type'] as String? ?? 'city',
);

Map<String, dynamic> _$$SearchLocationModelImplToJson(
  _$SearchLocationModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'imageUrl': instance.imageUrl,
  'type': instance.type,
};

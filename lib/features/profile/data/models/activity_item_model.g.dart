// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityItemModel _$ActivityItemModelFromJson(Map<String, dynamic> json) =>
    ActivityItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
      rating: (json['rating'] as num?)?.toDouble(),
      date: json['date'] == null
          ? null
          : DateTime.parse(json['date'] as String),
      status:
          $enumDecodeNullable(_$ActivityStatusEnumMap, json['status']) ??
          ActivityStatus.none,
      code: json['code'] as String?,
      restaurantName: json['restaurantName'] as String?,
      orderItems: (json['orderItems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ActivityItemModelToJson(ActivityItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': _$ActivityTypeEnumMap[instance.type]!,
      'rating': instance.rating,
      'date': instance.date?.toIso8601String(),
      'status': _$ActivityStatusEnumMap[instance.status]!,
      'code': instance.code,
      'restaurantName': instance.restaurantName,
      'orderItems': instance.orderItems,
    };

const _$ActivityTypeEnumMap = {
  ActivityType.itinerary: 'itinerary',
  ActivityType.rated: 'rated',
  ActivityType.reviewPending: 'reviewPending',
  ActivityType.food: 'food',
};

const _$ActivityStatusEnumMap = {
  ActivityStatus.none: 'none',
  ActivityStatus.upcoming: 'upcoming',
  ActivityStatus.preparing: 'preparing',
  ActivityStatus.delivered: 'delivered',
  ActivityStatus.pendingReview: 'pendingReview',
};

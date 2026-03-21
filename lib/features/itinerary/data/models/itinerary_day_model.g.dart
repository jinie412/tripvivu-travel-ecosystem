// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_day_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItineraryDayModel _$ItineraryDayModelFromJson(Map<String, dynamic> json) =>
    ItineraryDayModel(
      dayNumber: (json['day_number'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      temperature: (json['temperature'] as num?)?.toInt() ?? 0,
      totalDuration: json['total_duration'] as String,
      locationsCount: (json['locations_count'] as num).toInt(),
      dayBudget: (json['day_budget'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'VNĐ',
      activities:
          (json['activities'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ItineraryActivityModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ItineraryDayModelToJson(ItineraryDayModel instance) =>
    <String, dynamic>{
      'day_number': instance.dayNumber,
      'date': instance.date.toIso8601String(),
      'temperature': instance.temperature,
      'total_duration': instance.totalDuration,
      'locations_count': instance.locationsCount,
      'day_budget': instance.dayBudget,
      'currency': instance.currency,
      'activities': instance.activities,
    };

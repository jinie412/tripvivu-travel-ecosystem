// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItineraryDetailModel _$ItineraryDetailModelFromJson(
  Map<String, dynamic> json,
) => ItineraryDetailModel(
  id: json['id'] as String,
  title: json['title'] as String,
  destination: json['destination'] as String,
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
  status: json['status'] as String,
  isPublic: json['is_public'] as bool? ?? true,
  durationDays: (json['duration_days'] as num).toInt(),
  activitiesCount: (json['activities_count'] as num).toInt(),
  hotelsCount: (json['hotels_count'] as num).toInt(),
  transportTurns: (json['transport_turns'] as num).toInt(),
  estimatedBudget: (json['estimated_budget'] as num).toDouble(),
  spentBudget: (json['spent_budget'] as num).toDouble(),
  currency: json['currency'] as String? ?? 'VNĐ',
  days:
      (json['days'] as List<dynamic>?)
          ?.map((e) => ItineraryDayModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  notes:
      (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  centerCoordinate:
      (json['center_coordinate'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const [],
);

Map<String, dynamic> _$ItineraryDetailModelToJson(
  ItineraryDetailModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'destination': instance.destination,
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate.toIso8601String(),
  'status': instance.status,
  'is_public': instance.isPublic,
  'duration_days': instance.durationDays,
  'activities_count': instance.activitiesCount,
  'hotels_count': instance.hotelsCount,
  'transport_turns': instance.transportTurns,
  'estimated_budget': instance.estimatedBudget,
  'spent_budget': instance.spentBudget,
  'currency': instance.currency,
  'days': instance.days,
  'notes': instance.notes,
  'center_coordinate': instance.centerCoordinate,
};

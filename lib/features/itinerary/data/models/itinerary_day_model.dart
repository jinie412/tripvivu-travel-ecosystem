import 'itinerary_activity_model.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';

part 'itinerary_day_model.g.dart';

@JsonSerializable()
class ItineraryDayModel {
  @JsonKey(name: 'day_number')
  final int dayNumber;
  final DateTime date;
  final int temperature;
  @JsonKey(name: 'total_duration')
  final String totalDuration;
  @JsonKey(name: 'locations_count')
  final int locationsCount;
  @JsonKey(name: 'day_budget')
  final double dayBudget;
  final String currency;
  final List<ItineraryActivityModel> activities;

  const ItineraryDayModel({
    required this.dayNumber,
    required this.date,
    this.temperature = 0,
    required this.totalDuration,
    required this.locationsCount,
    required this.dayBudget,
    this.currency = 'VNĐ',
    this.activities = const [],
  });

  factory ItineraryDayModel.fromJson(Map<String, dynamic> json) =>
      _$ItineraryDayModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItineraryDayModelToJson(this);

  ItineraryDayEntity toEntity() {
    return ItineraryDayEntity(
      dayNumber: dayNumber,
      date: date,
      temperature: temperature,
      totalDuration: totalDuration,
      locationsCount: locationsCount,
      dayBudget: dayBudget,
      currency: currency,
      activities: activities.map((e) => e.toEntity()).toList(),
    );
  }
}
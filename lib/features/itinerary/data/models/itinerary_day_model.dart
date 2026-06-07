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

  factory ItineraryDayModel.fromJson(Map<String, dynamic> json) {
    // Backend date can be a formatted string or label, fallback to parsing or today
    DateTime dayDate = DateTime.now();
    if (json['date'] != null) {
      dayDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else if (json['dateLabel'] != null) {
      // e.g. "12/06", let's try to parse or just keep today
      dayDate = DateTime.now();
    }

    return ItineraryDayModel(
      dayNumber: json['day_number'] ?? json['dayNumber'] ?? 1,
      date: dayDate,
      temperature: json['temperature'] ?? json['weatherTemp'] ?? 0,
      totalDuration: json['total_duration'] ?? json['totalDuration'] ?? json['activeTimeStr'] ?? '',
      locationsCount: json['locations_count'] ?? json['locationsCount'] ?? 0,
      dayBudget: (json['day_budget'] ?? json['dayBudget'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'VNĐ',
      activities: (json['activities'] as List?)
              ?.map((e) => ItineraryActivityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

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
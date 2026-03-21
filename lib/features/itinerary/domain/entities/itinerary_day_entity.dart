import 'package:freezed_annotation/freezed_annotation.dart';
import 'itinerary_activity_entity.dart';

part 'itinerary_day_entity.freezed.dart';

@freezed
class ItineraryDayEntity with _$ItineraryDayEntity {
  const factory ItineraryDayEntity({
    required int dayNumber,
    required DateTime date,
    @Default(0) int temperature,
    required String totalDuration,
    required int locationsCount,
    required double dayBudget,
    @Default('VNĐ') String currency,
    @Default([]) List<ItineraryActivityEntity> activities,
  }) = _ItineraryDayEntity;
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:travel_advisor_mobile/features/trip_planner/domain/entities/trip_form.dart';

part 'trip_planner_state.freezed.dart';

@freezed
class TripPlannerState with _$TripPlannerState {
  const factory TripPlannerState.initial() = _Initial;
  const factory TripPlannerState.loading() = _Loading;
  const factory TripPlannerState.loaded({required TripForm tripForm}) = _Loaded;
  const factory TripPlannerState.generating() = _Generating;
  const factory TripPlannerState.success({required String itineraryId}) = _Success;
  const factory TripPlannerState.error(String message) = _Error;
}
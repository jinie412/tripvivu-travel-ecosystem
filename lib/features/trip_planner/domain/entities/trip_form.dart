import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_form.freezed.dart';

enum TripType { roundTrip, oneWay }

enum Transportation { flights, road, water }

@freezed
class TripForm with _$TripForm {
  const factory TripForm({
    @Default(TripType.roundTrip) TripType tripType,
    String? departureLocation,
    String? destinationLocation,
    @Default(Transportation.flights) Transportation transportation,
    @Default(1) int currentStep,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? topic,
    @Default(1) int adultCount,
    @Default(0) int childCount,
    @Default(5000000.0) double budget,
    @Default([]) List<String> foodPreferences,
  }) = _TripForm;
}
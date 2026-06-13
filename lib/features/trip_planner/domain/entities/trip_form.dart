import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_form.freezed.dart';

enum TripType { roundTrip, oneWay }

enum Transportation { car, motorbike }

@freezed
class TripForm with _$TripForm {
  const factory TripForm({
    @Default(TripType.roundTrip) TripType tripType,
    String? departureLocation,
    String? departureLocationId,
    String? destinationLocation,
    String? destinationLocationId,
    @Default(Transportation.car) Transportation transportation,
    @Default(1) int currentStep,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? tripIntent,
    @Default(1) int adultCount,
    @Default(0) int childCount,
    @Default(0.0) double budget,
    @Default([]) List<String> foodPreferences,
    // [TRIP_NAME_INPUT] Tên chuyến đi user nhập ở Bước 3 (tùy chọn)
    String? tripName,
  }) = _TripForm;
}

import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';

class CreateItineraryParams {
  final String userId;
  final String tripType;
  final String departureLocationId;
  final String destinationLocationId;
  final String transportMode;
  final String startDate;
  final String endDate;
  final String dailyStartTime;
  final String dailyEndTime;
  final String tripIntent;
  final int adultCount;
  final int childCount;
  final double budget;
  final List<String> foodPreferences;

  const CreateItineraryParams({
    required this.userId,
    required this.tripType,
    required this.departureLocationId,
    required this.destinationLocationId,
    required this.transportMode,
    required this.startDate,
    required this.endDate,
    required this.dailyStartTime,
    required this.dailyEndTime,
    required this.tripIntent,
    required this.adultCount,
    required this.childCount,
    required this.budget,
    required this.foodPreferences,
  });
}

class CreateItineraryUseCase {
  final ItineraryRepository _repository;
  CreateItineraryUseCase(this._repository);

  Future<String> call(CreateItineraryParams params) =>
      _repository.createItinerary(params);
}

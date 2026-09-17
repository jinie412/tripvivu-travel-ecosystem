import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';

class ExploreHomeData {
  final List<TripSuggestion> suggestions;
  final List<Destination> destinations;
  final List<CityRestaurant> restaurants;
  final List<CityHotel> hotels;
  final ItineraryEntity? currentItinerary;

  const ExploreHomeData({
    required this.suggestions,
    required this.destinations,
    required this.restaurants,
    required this.hotels,
    required this.currentItinerary,
  });
}

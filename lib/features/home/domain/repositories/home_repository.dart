import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/hotel.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';

/// Contract for the home/explore screen data.
/// Swap [MockHomeRepository] → [RemoteHomeRepository] in service_locator.dart
/// without changing any UI code.
abstract class HomeRepository {
  Future<List<TripSuggestion>> getSuggestions();
  Future<List<Destination>> getDestinations();
  Future<List<Hotel>> getHotels();
  Future<List<CityRestaurant>> getRestaurants();
}
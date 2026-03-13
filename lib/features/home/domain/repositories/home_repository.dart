import '../entities/destination.dart';
import '../entities/hotel.dart';
import '../entities/trip_suggestion.dart';

/// Contract for the home/explore screen data.
/// Swap [MockHomeRepository] → [RemoteHomeRepository] in service_locator.dart
/// without changing any UI code.
abstract class HomeRepository {
  Future<List<TripSuggestion>> getSuggestions();
  Future<List<Destination>> getDestinations();
  Future<List<Hotel>> getHotels();
}

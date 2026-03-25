import '../../../city_detail/domain/entities/city_entities.dart';
import '../../../home/domain/entities/destination.dart';

abstract class SavedRepository {
  Future<List<CityItinerary>> getFavoriteItineraries();
  Future<List<Destination>> getFavoritePlaces();
}

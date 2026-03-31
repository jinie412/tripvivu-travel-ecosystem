import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';

abstract class SavedRepository {
  Future<List<CityItinerary>> getFavoriteItineraries();
  Future<List<Destination>> getFavoritePlaces();
}
import 'package:travel_advisor_mobile/features/saved/domain/entities/favorite_itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/saved/domain/entities/favorite_place_entity.dart';

abstract class SavedRepository {
  Future<List<FavoriteItineraryEntity>> getFavoriteItineraries({int page = 1, int limit = 5});
  Future<List<FavoritePlaceEntity>> getFavoritePlaces({int page = 1, int limit = 5});
}
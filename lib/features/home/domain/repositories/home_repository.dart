import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/explore_home_data.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';

/// Contract for the home/explore screen data.
abstract class HomeRepository {
  Future<ExploreHomeData> getExploreHome();
  Future<List<CityRestaurant>> getRestaurants({int limit = 5});
  Future<List<TripSuggestion>> getPublicSuggestions({int page = 1, int limit = 50});
  Future<List<Destination>> getFeaturedDestinations({int page = 1, int limit = 50});
  Future<List<CityRestaurant>> getRestaurantsByCategories({
    required List<String> categories,
    int page = 1,
    int limitPerCategory = 50,
  });
  Future<List<CityHotel>> getHotelsByCategories({
    required List<String> categories,
    int page = 1,
    int limitPerCategory = 50,
  });
}
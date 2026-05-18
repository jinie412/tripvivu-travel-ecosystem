import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/data/datasources/home_datasource.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/explore_home_data.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';
import 'package:travel_advisor_mobile/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDataSource _dataSource;
  HomeRepositoryImpl(this._dataSource);

  @override
  Future<ExploreHomeData> getExploreHome() async {
    final payload = await _dataSource.getExploreHome();

    return ExploreHomeData(
      suggestions: payload.suggestions.map((m) => m.toEntity()).toList(),
      destinations: payload.destinations.map((m) => m.toEntity()).toList(),
      restaurants: payload.restaurants,
      hotels: payload.hotels,
      currentItinerary: payload.currentItinerary,
    );
  }

  @override
  Future<List<CityRestaurant>> getRestaurants({int limit = 5}) async {
    return _dataSource.getRestaurants(limit: limit);
  }

  @override
  Future<List<TripSuggestion>> getPublicSuggestions({int limit = 50}) async {
    final models = await _dataSource.getPublicSuggestions(limit: limit);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Destination>> getFeaturedDestinations({int limit = 50}) async {
    final models = await _dataSource.getFeaturedDestinations(limit: limit);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<CityRestaurant>> getRestaurantsByCategories({
    required List<String> categories,
    int limitPerCategory = 50,
  }) async {
    return _dataSource.getRestaurantsByCategories(
      categories: categories,
      limitPerCategory: limitPerCategory,
    );
  }

  @override
  Future<List<CityHotel>> getHotelsByCategories({
    required List<String> categories,
    int limitPerCategory = 50,
  }) async {
    return _dataSource.getHotelsByCategories(
      categories: categories,
      limitPerCategory: limitPerCategory,
    );
  }
}
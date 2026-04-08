import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/explore_home_data.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';
import 'package:travel_advisor_mobile/features/home/domain/repositories/home_repository.dart';

class GetExploreHomeUseCase {
  final HomeRepository _repo;
  GetExploreHomeUseCase(this._repo);
  Future<ExploreHomeData> call() => _repo.getExploreHome();
}

class GetRestaurantsUseCase {
  final HomeRepository _repo;
  GetRestaurantsUseCase(this._repo);
  Future<List<CityRestaurant>> call({int limit = 5}) => _repo.getRestaurants(limit: limit);
}

class GetPublicSuggestionsUseCase {
  final HomeRepository _repo;
  GetPublicSuggestionsUseCase(this._repo);
  Future<List<TripSuggestion>> call({int limit = 50}) =>
      _repo.getPublicSuggestions(limit: limit);
}

class GetFeaturedDestinationsUseCase {
  final HomeRepository _repo;
  GetFeaturedDestinationsUseCase(this._repo);
  Future<List<Destination>> call({int limit = 50}) =>
      _repo.getFeaturedDestinations(limit: limit);
}

class GetRestaurantsByCategoriesUseCase {
  final HomeRepository _repo;
  GetRestaurantsByCategoriesUseCase(this._repo);
  Future<List<CityRestaurant>> call({
    required List<String> categories,
    int limitPerCategory = 50,
  }) =>
      _repo.getRestaurantsByCategories(
        categories: categories,
        limitPerCategory: limitPerCategory,
      );
}

class GetHotelsByCategoriesUseCase {
  final HomeRepository _repo;
  GetHotelsByCategoriesUseCase(this._repo);
  Future<List<CityHotel>> call({
    required List<String> categories,
    int limitPerCategory = 50,
  }) =>
      _repo.getHotelsByCategories(
        categories: categories,
        limitPerCategory: limitPerCategory,
      );
}
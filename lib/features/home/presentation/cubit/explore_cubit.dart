import 'explore_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/explore_home_data.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';
import 'package:travel_advisor_mobile/features/home/domain/usecases/home_usecases.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final GetExploreHomeUseCase _getExploreHome;
  final GetRestaurantsUseCase _getRestaurants;
  final GetPublicSuggestionsUseCase _getPublicSuggestions;
  final GetFeaturedDestinationsUseCase _getFeaturedDestinations;
  final GetRestaurantsByCategoriesUseCase _getRestaurantsByCategories;
  final GetHotelsByCategoriesUseCase _getHotelsByCategories;

  ExploreCubit({
    required GetExploreHomeUseCase getExploreHome,
    required GetRestaurantsUseCase getRestaurants,
    required GetPublicSuggestionsUseCase getPublicSuggestions,
    required GetFeaturedDestinationsUseCase getFeaturedDestinations,
    required GetRestaurantsByCategoriesUseCase getRestaurantsByCategories,
    required GetHotelsByCategoriesUseCase getHotelsByCategories,
  })  : _getExploreHome = getExploreHome,
        _getRestaurants = getRestaurants,
        _getPublicSuggestions = getPublicSuggestions,
        _getFeaturedDestinations = getFeaturedDestinations,
        _getRestaurantsByCategories = getRestaurantsByCategories,
        _getHotelsByCategories = getHotelsByCategories,
        super(const ExploreInitial());

  Future<void> loadData() async {
    emit(const ExploreLoading());
    try {
      final results = await Future.wait<dynamic>([
        _getExploreHome(),
        _getRestaurants(limit: 5),
        _getPublicSuggestions(limit: 200),
        _getFeaturedDestinations(limit: 200),
        _getRestaurantsByCategories(
          categories: const ['restaurant', 'nhà hàng'],
          limitPerCategory: 200,
        ),
        _getHotelsByCategories(
          categories: const ['hotel', 'khách sạn'],
          limitPerCategory: 200,
        ),
      ]);

      final ExploreHomeData data = results[0] as ExploreHomeData;
      final List<CityRestaurant> topRestaurants = results[1] as List<CityRestaurant>;
      final List<TripSuggestion> allSuggestions = results[2] as List<TripSuggestion>;
      final List<Destination> allDestinations = results[3] as List<Destination>;
      final List<CityRestaurant> allRestaurants = results[4] as List<CityRestaurant>;
      final List<CityHotel> allHotels = results[5] as List<CityHotel>;

      emit(ExploreLoaded(
        suggestions: data.suggestions.take(5).toList(),
        destinations: data.destinations.take(5).toList(),
        hotels: data.hotels.take(5).toList(),
        restaurants: topRestaurants.take(5).toList(),
        allSuggestions: allSuggestions,
        allDestinations: allDestinations,
        allHotels: allHotels,
        allRestaurants: allRestaurants,
        currentItinerary: data.currentItinerary,
      ));
    } catch (e) {
      emit(ExploreError(e.toString()));
    }
  }
}
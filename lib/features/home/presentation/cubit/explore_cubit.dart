import 'explore_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/explore_home_data.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';
import 'package:travel_advisor_mobile/features/home/domain/usecases/home_usecases.dart';
import 'package:travel_advisor_mobile/core/config/app_config.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final GetExploreHomeUseCase _getExploreHome;
  final GetPublicSuggestionsUseCase _getPublicSuggestions;
  final GetFeaturedDestinationsUseCase _getFeaturedDestinations;
  final GetRestaurantsByCategoriesUseCase _getRestaurantsByCategories;
  final GetHotelsByCategoriesUseCase _getHotelsByCategories;

  ExploreCubit({
    required GetExploreHomeUseCase getExploreHome,
    required GetPublicSuggestionsUseCase getPublicSuggestions,
    required GetFeaturedDestinationsUseCase getFeaturedDestinations,
    required GetRestaurantsByCategoriesUseCase getRestaurantsByCategories,
    required GetHotelsByCategoriesUseCase getHotelsByCategories,
  })  : _getExploreHome = getExploreHome,
        _getPublicSuggestions = getPublicSuggestions,
        _getFeaturedDestinations = getFeaturedDestinations,
        _getRestaurantsByCategories = getRestaurantsByCategories,
        _getHotelsByCategories = getHotelsByCategories,
        super(const ExploreInitial());

  /// 🔧 CHẾ ĐỘ DEMO: Set true để bỏ qua lỗi Backend và dùng dữ liệu mẫu
  static const bool kDemoMode = AppConfig.kUseMockData;

  Future<T> _safeLoad<T>(Future<T> Function() loader, T fallback) async {
    try {
      return await loader();
    } catch (_) {
      return fallback;
    }
  }

  static const ExploreHomeData _emptyHome = ExploreHomeData(
    suggestions: <TripSuggestion>[],
    destinations: <Destination>[],
    hotels: <CityHotel>[],
    currentItinerary: null,
  );

  Future<void> loadData() async {
    emit(const ExploreLoading());
    try {
      final ExploreHomeData data =
          await _safeLoad<ExploreHomeData>(_getExploreHome.call, _emptyHome);

      final List<CityRestaurant> topRestaurants =
          await _safeLoad<List<CityRestaurant>>(
        () => _getRestaurantsByCategories(
          categories: const ['ẩm thực'],
          limitPerCategory: 5,
        ),
        const <CityRestaurant>[],
      );

      final List<TripSuggestion> allSuggestions =
          await _safeLoad<List<TripSuggestion>>(
        () => _getPublicSuggestions(limit: 200),
        data.suggestions,
      );

      final List<Destination> allDestinations =
          await _safeLoad<List<Destination>>(
        () => _getFeaturedDestinations(limit: 200),
        data.destinations,
      );

      final List<CityRestaurant> allRestaurants =
          await _safeLoad<List<CityRestaurant>>(
        () => _getRestaurantsByCategories(
          categories: const ['ẩm thực'],
          limitPerCategory: 200,
        ),
        topRestaurants,
      );

      final List<CityHotel> allHotels = await _safeLoad<List<CityHotel>>(
        () => _getHotelsByCategories(
          categories: const ['lưu trú'],
          limitPerCategory: 200,
        ),
        data.hotels,
      );

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
      if (kDemoMode) {
        // ⚠️ BACKEND NOTE: Mock dữ liệu trang chủ cho Demo
        final mockExplore = ExploreHomeData(
          suggestions: [
            const TripSuggestion(
              id: 's1', title: 'Khám phá ẩm thực Huế', 
              imageUrl: 'https://images.unsplash.com/photo-1584824486509-112e4181ff6b?w=400',
              days: '3 ngày', location: 'Huế', views: '1.2k', likes: '450',
            ),
            const TripSuggestion(
              id: 's2', title: 'Chụp ảnh tại Hội An', 
              imageUrl: 'https://images.unsplash.com/photo-1599708149128-01998b262143?w=400',
              days: '2 ngày', location: 'Quảng Nam', views: '2.5k', likes: '890',
            ),
          ],
          destinations: [
            const Destination(id: 'd1', name: 'Đà Nẵng', imageUrl: 'https://images.unsplash.com/photo-1559592471-744e99c1586e?w=400'),
            const Destination(id: 'd2', name: 'Đà Lạt', imageUrl: 'https://images.unsplash.com/photo-1571474004502-c1def214ac6d?w=400'),
          ],
          hotels: [],
          currentItinerary: null,
        );

        emit(ExploreLoaded(
          suggestions: mockExplore.suggestions,
          destinations: mockExplore.destinations,
          hotels: const [],
          restaurants: const [],
          allSuggestions: mockExplore.suggestions,
          allDestinations: mockExplore.destinations,
          allHotels: const [],
          allRestaurants: const [],
          currentItinerary: null,
        ));
      } else {
        emit(ExploreError(e.toString()));
      }
    }
  }
}

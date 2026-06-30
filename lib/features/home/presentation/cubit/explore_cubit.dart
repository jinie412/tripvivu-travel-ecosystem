import 'dart:async';

import 'explore_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/explore_home_data.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';
import 'package:travel_advisor_mobile/features/home/domain/usecases/home_usecases.dart';
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final GetExploreHomeUseCase _getExploreHome;
  final GetPublicSuggestionsUseCase _getPublicSuggestions;
  final GetFeaturedDestinationsUseCase _getFeaturedDestinations;
  final GetRestaurantsByCategoriesUseCase _getRestaurantsByCategories;
  final GetHotelsByCategoriesUseCase _getHotelsByCategories;

  List<TripSuggestion>? _cachedSuggestions;
  List<Destination>? _cachedDestinations;
  List<CityHotel>? _cachedHotels;
  List<CityRestaurant>? _cachedRestaurants;

  ExploreCubit({
    required GetExploreHomeUseCase getExploreHome,
    required GetPublicSuggestionsUseCase getPublicSuggestions,
    required GetFeaturedDestinationsUseCase getFeaturedDestinations,
    required GetRestaurantsByCategoriesUseCase getRestaurantsByCategories,
    required GetHotelsByCategoriesUseCase getHotelsByCategories,
  }) : _getExploreHome = getExploreHome,
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

  Future<List<TripSuggestion>> loadAllSuggestions({
    bool refresh = false,
  }) async {
    if (!refresh && _cachedSuggestions != null) {
      return _cachedSuggestions!;
    }

    if (kDemoMode && state is ExploreLoaded) {
      final loaded = state as ExploreLoaded;
      _cachedSuggestions = loaded.allSuggestions.isNotEmpty
          ? loaded.allSuggestions
          : loaded.suggestions;
      return _cachedSuggestions!;
    }

    final result = await _safeLoad<List<TripSuggestion>>(
      () => _getPublicSuggestions(limit: 50),
      const <TripSuggestion>[],
    );
    _cachedSuggestions = result;
    return result;
  }

  void updateCurrentItineraryStatus(
    String itineraryId,
    ItineraryStatus status,
  ) {
    final current = state;
    if (current is! ExploreLoaded) return;
    final item = current.currentItinerary;
    if (item == null || item.id != itineraryId) return;

    emit(
      ExploreLoaded(
        suggestions: current.suggestions,
        destinations: current.destinations,
        hotels: current.hotels,
        restaurants: current.restaurants,
        allSuggestions: current.allSuggestions,
        allDestinations: current.allDestinations,
        allHotels: current.allHotels,
        allRestaurants: current.allRestaurants,
        currentItinerary: item.copyWith(
          status: status,
          trackingActive: status == ItineraryStatus.ongoing,
        ),
      ),
    );
  }

  Future<List<TripSuggestion>> loadSuggestionsPage({
    required int page,
    int limit = 10,
  }) async {
    return _safeLoad<List<TripSuggestion>>(
      () => _getPublicSuggestions(page: page, limit: limit),
      const <TripSuggestion>[],
    );
  }

  Future<List<Destination>> loadAllDestinations({bool refresh = false}) async {
    if (!refresh && _cachedDestinations != null) {
      return _cachedDestinations!;
    }

    if (kDemoMode && state is ExploreLoaded) {
      final loaded = state as ExploreLoaded;
      _cachedDestinations = loaded.allDestinations.isNotEmpty
          ? loaded.allDestinations
          : loaded.destinations;
      return _cachedDestinations!;
    }

    final result = await _safeLoad<List<Destination>>(
      () => _getFeaturedDestinations(limit: 50),
      const <Destination>[],
    );
    _cachedDestinations = result;
    return result;
  }

  Future<List<Destination>> loadDestinationsPage({
    required int page,
    int limit = 10,
  }) async {
    return _safeLoad<List<Destination>>(
      () => _getFeaturedDestinations(page: page, limit: limit),
      const <Destination>[],
    );
  }

  Future<List<CityRestaurant>> loadAllRestaurants({
    bool refresh = false,
  }) async {
    if (!refresh && _cachedRestaurants != null) {
      return _cachedRestaurants!;
    }

    if (kDemoMode && state is ExploreLoaded) {
      final loaded = state as ExploreLoaded;
      _cachedRestaurants = loaded.allRestaurants.isNotEmpty
          ? loaded.allRestaurants
          : loaded.restaurants;
      return _cachedRestaurants!;
    }

    final result = await _safeLoad<List<CityRestaurant>>(
      () => _getRestaurantsByCategories(
        categories: const ['ẩm thực'],
        limitPerCategory: 50,
      ),
      const <CityRestaurant>[],
    );
    var finalResult = result;
    _cachedRestaurants = finalResult;

    // Fallback: if category-based fetch returned empty, try loading the
    // Explore home payload and use its restaurants list. This helps when
    // the /explore/places?category=... endpoint fails to return items.
    if ((finalResult.isEmpty)) {
      try {
        final home = await _safeLoad<ExploreHomeData>(_getExploreHome.call, _emptyHome);
        finalResult = home.restaurants;
        _cachedRestaurants = finalResult;
      } catch (_) {
        // swallow - keep finalResult as empty list
      }
    }
    if (state is ExploreLoaded) {
      final cur = state as ExploreLoaded;
      emit(ExploreLoaded(
        suggestions: cur.suggestions,
        destinations: cur.destinations,
        hotels: cur.hotels,
        restaurants: cur.restaurants,
        allSuggestions: cur.allSuggestions,
        allDestinations: cur.allDestinations,
        allHotels: cur.allHotels,
        allRestaurants: finalResult,
        currentItinerary: cur.currentItinerary,
      ));
    }
    return result;
  }

  Future<List<CityRestaurant>> loadRestaurantsPage({
    required int page,
    int limit = 10,
  }) async {
    return _safeLoad<List<CityRestaurant>>(
      () => _getRestaurantsByCategories(
        categories: const ['ẩm thực'],
        page: page,
        limitPerCategory: limit,
      ),
      const <CityRestaurant>[],
    );
  }

  Future<List<CityHotel>> loadAllHotels({bool refresh = false}) async {
    if (!refresh && _cachedHotels != null) {
      return _cachedHotels!;
    }

    if (kDemoMode && state is ExploreLoaded) {
      final loaded = state as ExploreLoaded;
      _cachedHotels = loaded.allHotels.isNotEmpty
          ? loaded.allHotels
          : loaded.hotels;
      return _cachedHotels!;
    }

    final result = await _safeLoad<List<CityHotel>>(
      () => _getHotelsByCategories(
        categories: const ['lưu trú'],
        limitPerCategory: 50,
      ),
      const <CityHotel>[],
    );
    _cachedHotels = result;
    if (state is ExploreLoaded) {
      final cur = state as ExploreLoaded;
      emit(ExploreLoaded(
        suggestions: cur.suggestions,
        destinations: cur.destinations,
        hotels: cur.hotels,
        restaurants: cur.restaurants,
        allSuggestions: cur.allSuggestions,
        allDestinations: cur.allDestinations,
        allHotels: result,
        allRestaurants: cur.allRestaurants,
        currentItinerary: cur.currentItinerary,
      ));
    }
    return result;
  }

  Future<List<CityHotel>> loadHotelsPage({
    required int page,
    int limit = 10,
  }) async {
    return _safeLoad<List<CityHotel>>(
      () => _getHotelsByCategories(
        categories: const ['lưu trú'],
        page: page,
        limitPerCategory: limit,
      ),
      const <CityHotel>[],
    );
  }

  void applyFavoriteChange(FavoriteChangedEvent event) {
    if (event.type == FavoriteTargetType.itinerary) {
      _cachedSuggestions = _updateSuggestionsFavorite(
        _cachedSuggestions,
        event.id,
        event.isFavorite,
      );
    } else {
      _cachedRestaurants = _updateRestaurantsFavorite(
        _cachedRestaurants,
        event.id,
        event.isFavorite,
      );
      _cachedHotels = _updateHotelsFavorite(
        _cachedHotels,
        event.id,
        event.isFavorite,
      );
    }

    final current = state;
    if (current is! ExploreLoaded) {
      return;
    }

    emit(
      ExploreLoaded(
        suggestions: event.type == FavoriteTargetType.itinerary
            ? _updateSuggestionsFavorite(
                current.suggestions,
                event.id,
                event.isFavorite,
              )!
            : current.suggestions,
        destinations: current.destinations,
        hotels: event.type == FavoriteTargetType.place
            ? _updateHotelsFavorite(
                current.hotels,
                event.id,
                event.isFavorite,
              )!
            : current.hotels,
        restaurants: event.type == FavoriteTargetType.place
            ? _updateRestaurantsFavorite(
                current.restaurants,
                event.id,
                event.isFavorite,
              )!
            : current.restaurants,
        allSuggestions: event.type == FavoriteTargetType.itinerary
            ? _updateSuggestionsFavorite(
                current.allSuggestions,
                event.id,
                event.isFavorite,
              )!
            : current.allSuggestions,
        allDestinations: current.allDestinations,
        allHotels: event.type == FavoriteTargetType.place
            ? _updateHotelsFavorite(
                current.allHotels,
                event.id,
                event.isFavorite,
              )!
            : current.allHotels,
        allRestaurants: event.type == FavoriteTargetType.place
            ? _updateRestaurantsFavorite(
                current.allRestaurants,
                event.id,
                event.isFavorite,
              )!
            : current.allRestaurants,
        currentItinerary: current.currentItinerary,
      ),
    );
  }

  List<TripSuggestion>? _updateSuggestionsFavorite(
    List<TripSuggestion>? items,
    String id,
    bool isFavorite,
  ) {
    if (items == null) return null;
    return items
        .map((item) =>
            item.id == id ? item.copyWith(isFavorite: isFavorite) : item)
        .toList();
  }

  List<CityRestaurant>? _updateRestaurantsFavorite(
    List<CityRestaurant>? items,
    String id,
    bool isFavorite,
  ) {
    if (items == null) return null;
    return items
        .map((item) =>
            item.id == id ? item.copyWith(isFavorite: isFavorite) : item)
        .toList();
  }

  List<CityHotel>? _updateHotelsFavorite(
    List<CityHotel>? items,
    String id,
    bool isFavorite,
  ) {
    if (items == null) return null;
    return items
        .map((item) =>
            item.id == id ? item.copyWith(isFavorite: isFavorite) : item)
        .toList();
  }

  void _loadRatedDestinations() {
    _getFeaturedDestinations(limit: 5).then((ratedDests) {
      if (isClosed || ratedDests.isEmpty) return;
      final sorted = List<Destination>.from(ratedDests)
        ..sort((a, b) {
          final r = b.averageRating.compareTo(a.averageRating);
          return r != 0 ? r : b.reviewCount.compareTo(a.reviewCount);
        });
      final cur = state;
      if (cur is ExploreLoaded) {
        emit(ExploreLoaded(
          suggestions: cur.suggestions,
          destinations: sorted.take(5).toList(),
          restaurants: cur.restaurants,
          hotels: cur.hotels,
          allSuggestions: cur.allSuggestions,
          allDestinations: cur.allDestinations,
          allHotels: cur.allHotels,
          allRestaurants: cur.allRestaurants,
          currentItinerary: cur.currentItinerary,
        ));
      }
    }).catchError((_) {});
  }

  Future<void> _silentRefresh() async {
    try {
      final data = await _getExploreHome(forceRefresh: true);
      if (!isClosed && (data.suggestions.isNotEmpty || data.destinations.isNotEmpty)) {
        _cachedSuggestions = null;
        _cachedDestinations = null;
        _cachedRestaurants = null;
        _cachedHotels = null;
        emit(
          ExploreLoaded(
            suggestions: data.suggestions.take(5).toList(),
            destinations: data.destinations.take(5).toList(),
            restaurants: data.restaurants.take(5).toList(),
            hotels: data.hotels.take(5).toList(),
            allSuggestions: const <TripSuggestion>[],
            allDestinations: const <Destination>[],
            allHotels: const <CityHotel>[],
            allRestaurants: const <CityRestaurant>[],
            currentItinerary: data.currentItinerary,
          ),
        );
        _loadRatedDestinations();
      }
    } catch (_) {
      // Keep showing existing state on refresh failure
    }
  }

  static const ExploreHomeData _emptyHome = ExploreHomeData(
    suggestions: <TripSuggestion>[],
    destinations: <Destination>[],
    restaurants: <CityRestaurant>[],
    hotels: <CityHotel>[],
    currentItinerary: null,
  );

  Future<void> loadData({bool refresh = false}) async {
    // If data is already loaded (singleton cubit persists across navigations),
    // show the current state immediately and refresh silently in the background.
    if (!refresh && state is ExploreLoaded) {
      _silentRefresh();
      return;
    }

    if (!refresh) emit(const ExploreLoading());
    try {
      final ExploreHomeData data = await _safeLoad<ExploreHomeData>(
        () => _getExploreHome(forceRefresh: refresh),
        _emptyHome,
      );

      _cachedSuggestions = null;
      _cachedDestinations = null;
      _cachedRestaurants = null;
      _cachedHotels = null;

      emit(
        ExploreLoaded(
          suggestions: data.suggestions.take(5).toList(),
          destinations: data.destinations.take(5).toList(),
          restaurants: data.restaurants.take(5).toList(),
          hotels: data.hotels.take(5).toList(),
          allSuggestions: const <TripSuggestion>[],
          allDestinations: const <Destination>[],
          allHotels: const <CityHotel>[],
          allRestaurants: const <CityRestaurant>[],
          currentItinerary: data.currentItinerary,
        ),
      );
      _loadRatedDestinations();
    } catch (e) {
      if (refresh) return;
      if (kDemoMode) {
        // ⚠️ BACKEND NOTE: Mock dữ liệu trang chủ cho Demo
        final mockExplore = ExploreHomeData(
          suggestions: [
            const TripSuggestion(
              id: 's1',
              title: 'Khám phá ẩm thực Huế',
              imageUrl:
                  'https://images.unsplash.com/photo-1584824486509-112e4181ff6b?w=400',
              days: '3 ngày',
              location: 'Huế',
              views: '1.2k',
              likes: '450',
            ),
            const TripSuggestion(
              id: 's2',
              title: 'Chụp ảnh tại Hội An',
              imageUrl:
                  'https://images.unsplash.com/photo-1599708149128-01998b262143?w=400',
              days: '2 ngày',
              location: 'Quảng Nam',
              views: '2.5k',
              likes: '890',
            ),
          ],
          destinations: [
            const Destination(
              id: 'd1',
              name: 'Đà Nẵng',
              imageUrl:
                  'https://images.unsplash.com/photo-1559592471-744e99c1586e?w=400',
            ),
            const Destination(
              id: 'd2',
              name: 'Đà Lạt',
              imageUrl:
                  'https://images.unsplash.com/photo-1571474004502-c1def214ac6d?w=400',
            ),
          ],
          restaurants: const [],
          hotels: const [],
          currentItinerary: null,
        );

        emit(
          ExploreLoaded(
            suggestions: mockExplore.suggestions,
            destinations: mockExplore.destinations,
            hotels: const [],
            restaurants: const [],
            allSuggestions: mockExplore.suggestions,
            allDestinations: mockExplore.destinations,
            allHotels: const [],
            allRestaurants: const [],
            currentItinerary: null,
          ),
        );
      } else {
        emit(ExploreError(e.toString()));
      }
    }
  }
}

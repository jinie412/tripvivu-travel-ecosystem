import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/filter_enums.dart';

part 'city_detail_state.freezed.dart';

@freezed
class CityDetailState with _$CityDetailState {
  const factory CityDetailState.initial() = _Initial;
  const factory CityDetailState.loading() = _Loading;
  const factory CityDetailState.loaded(
    CityOverview overview,
    int activeTab, {
    // === Filter state cho từng tab ===
    @Default(ActivityFilter()) ActivityFilter activityFilter,
    @Default(RestaurantFilter()) RestaurantFilter restaurantFilter,
    @Default(HotelFilter()) HotelFilter hotelFilter,
    // === Danh sách đã được lọc/sắp xếp (UI đọc từ đây) ===
    @Default([]) List<CityActivity> filteredActivities,
    @Default([]) List<CityRestaurant> filteredRestaurants,
    @Default([]) List<CityHotel> filteredHotels,
  }) = _Loaded;
  const factory CityDetailState.error(String message) = _Error;
}
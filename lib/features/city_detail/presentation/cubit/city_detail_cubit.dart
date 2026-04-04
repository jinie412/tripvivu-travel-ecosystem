import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/city_detail/domain/entities/filter_enums.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/usecases/get_city_overview_usecase.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/cubit/city_detail_state.dart';

class CityDetailCubit extends Cubit<CityDetailState> {
  final GetCityOverviewUseCase _getCityOverview;

  CityDetailCubit(this._getCityOverview) : super(const CityDetailState.initial());

  /// Tải dữ liệu tổng quan của thành phố.
  /// Sau khi load xong, khởi tạo filteredList = danh sách gốc (chưa filter).
  Future<void> loadCityDetail(String cityId) async {
    emit(const CityDetailState.loading());
    try {
      final overview = await _getCityOverview(cityId);
      emit(CityDetailState.loaded(
        overview,
        0, // Tab mặc định: Tổng quan
        filteredActivities: overview.activities,
        filteredRestaurants: overview.restaurants,
        filteredHotels: overview.hotels,
      ));
    } catch (e) {
      emit(CityDetailState.error(e.toString()));
    }
  }

  /// Chuyển tab
  void changeTab(int index) {
    state.mapOrNull(
      loaded: (s) => emit(s.copyWith(activeTab: index)),
    );
  }

  // ============================================================
  // FILTER & SORT — Tab Hoạt động tham quan
  // ============================================================

  /// Cập nhật bộ lọc cho tab "Hoạt động tham quan" và áp dụng lọc.
  void updateActivityFilter(ActivityFilter filter) {
    state.mapOrNull(
      loaded: (s) {
        var result = s.overview.activities.toList();

        // 1. Lọc theo loại hình (chọn nhiều, rỗng = tất cả)
        if (filter.categories.isNotEmpty) {
          result = result.where((a) {
            return filter.categories.any((c) => c.name == a.category);
          }).toList();
        }

        // 2. Lọc theo khoảng giá (chọn 1)
        if (filter.priceType != ActivityPriceType.all) {
          result = result.where((a) => a.priceType == filter.priceType.name).toList();
        }

        // 3. Lọc theo khu vực
        if (filter.district != null && filter.district!.isNotEmpty) {
          result = result.where((a) => a.district == filter.district).toList();
        }

        // 5. Sắp xếp
        switch (filter.sortOption) {
          case SortOption.mostPopular:
            result.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
            break;
          case SortOption.highestRated:
            result.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          default:
            break;
        }

        emit(s.copyWith(
          activityFilter: filter,
          filteredActivities: result,
        ));
      },
    );
  }

  /// Đặt lại filter cho tab Hoạt động về mặc định
  void resetActivityFilter() {
    updateActivityFilter(const ActivityFilter());
  }

  // ============================================================
  // FILTER & SORT — Tab Nhà hàng
  // ============================================================

  /// Cập nhật bộ lọc cho tab "Nhà hàng" và áp dụng lọc.
  void updateRestaurantFilter(RestaurantFilter filter) {
    state.mapOrNull(
      loaded: (s) {
        var result = s.overview.restaurants.toList();

        // 1. Lọc theo danh mục (chọn nhiều)
        if (filter.cuisines.isNotEmpty) {
          result = result.where((r) {
            return filter.cuisines.any((c) => c.name == r.cuisine);
          }).toList();
        }

        // 2. Lọc theo mức giá (chọn 1)
        if (filter.priceLevel != RestaurantPriceLevel.all) {
          final priceLevelStr = filter.priceLevel == RestaurantPriceLevel.midRange
              ? 'mid_range'
              : filter.priceLevel.name;
          result = result.where((r) => r.priceLevel == priceLevelStr).toList();
        }

        // 3. Lọc theo tiện ích (phải có TẤT CẢ tiện ích đã chọn)
        if (filter.amenities.isNotEmpty) {
          result = result.where((r) {
            return filter.amenities.every(
              (amenity) => r.amenities.contains(amenity.name),
            );
          }).toList();
        }

        // 5. Sắp xếp
        switch (filter.sortOption) {
          case SortOption.highestRated:
            result.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case SortOption.cheapest:
            // Sort theo thứ tự: budget < mid_range < premium
            result.sort((a, b) => _priceLevelOrder(a.priceLevel)
                .compareTo(_priceLevelOrder(b.priceLevel)));
            break;
          default:
            break;
        }

        emit(s.copyWith(
          restaurantFilter: filter,
          filteredRestaurants: result,
        ));
      },
    );
  }

  /// Đặt lại filter cho tab Nhà hàng về mặc định
  void resetRestaurantFilter() {
    updateRestaurantFilter(const RestaurantFilter());
  }

  /// Helper: Chuyển priceLevel string thành số thứ tự để so sánh
  int _priceLevelOrder(String priceLevel) {
    switch (priceLevel) {
      case 'budget':
        return 0;
      case 'mid_range':
        return 1;
      case 'premium':
        return 2;
      default:
        return 1;
    }
  }

  // ============================================================
  // FILTER & SORT — Tab Khách sạn
  // ============================================================

  /// Cập nhật bộ lọc cho tab "Khách sạn" và áp dụng lọc.
  void updateHotelFilter(HotelFilter filter) {
    state.mapOrNull(
      loaded: (s) {
        var result = s.overview.hotels.toList();

        // 2. Lọc theo khoảng giá (RangeSlider)
        if (filter.minPrice > 0 || filter.maxPrice > 0) {
          result = result.where((h) {
            final aboveMin = h.priceValue >= filter.minPrice;
            final belowMax = filter.maxPrice <= 0 || h.priceValue <= filter.maxPrice;
            return aboveMin && belowMax;
          }).toList();
        }

        // 3. Lọc theo loại hình lưu trú (chọn nhiều)
        if (filter.accommodationTypes.isNotEmpty) {
          result = result.where((h) {
            return filter.accommodationTypes.any((t) => t.name == h.accommodationType);
          }).toList();
        }

        // 4. Lọc theo tiện nghi (phải có TẤT CẢ tiện nghi đã chọn)
        if (filter.amenities.isNotEmpty) {
          result = result.where((h) {
            return filter.amenities.every(
              (amenity) => h.amenities.contains(amenity.name),
            );
          }).toList();
        }

        // 5. Sắp xếp
        switch (filter.sortOption) {
          case SortOption.highestRated:
            result.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case SortOption.cheapest:
            result.sort((a, b) => a.priceValue.compareTo(b.priceValue));
            break;
          default:
            break;
        }

        emit(s.copyWith(
          hotelFilter: filter,
          filteredHotels: result,
        ));
      },
    );
  }

  /// Đặt lại filter cho tab Khách sạn về mặc định
  void resetHotelFilter() {
    updateHotelFilter(const HotelFilter());
  }
}
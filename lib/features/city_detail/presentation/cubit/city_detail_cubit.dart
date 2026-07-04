import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/city_detail/domain/entities/filter_enums.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/usecases/get_city_overview_usecase.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/cubit/city_detail_state.dart';

class CityDetailCubit extends Cubit<CityDetailState> {
  final GetCityOverviewUseCase _getCityOverview;
  String currentCityName = "";

  CityDetailCubit(this._getCityOverview)
    : super(const CityDetailState.initial());

  /// Tải dữ liệu tổng quan của thành phố.
  /// Sau khi load xong, khởi tạo filteredList = danh sách gốc (chưa filter).
  Future<void> loadCityDetail(String cityId, String cityName) async {
    emit(const CityDetailState.loading());
    try {
      currentCityName = cityName;
      final overview = await _getCityOverview(cityId);
      emit(
        CityDetailState.loaded(
          overview,
          0,
          filteredActivities: overview.activities,
          filteredRestaurants: overview.restaurants,
          filteredHotels: overview.hotels,
          itineraries: overview.itineraries,
        ),
      );
    } catch (e) {
      emit(CityDetailState.error(e.toString()));
    }
  }

  /// Chuyển tab
  void changeTab(int index) {
    state.mapOrNull(loaded: (s) => emit(s.copyWith(activeTab: index)));
  }

  /// Sắp xếp chung cho cả 3 tab. Sort ổn định nhờ tie-break:
  /// rating hòa thì xét reviewCount và ngược lại.
  void _sortInPlace<T>(
    List<T> items,
    SortOption option, {
    required double Function(T) ratingOf,
    required int Function(T) reviewCountOf,
  }) {
    switch (option) {
      case SortOption.highestRated:
        items.sort((a, b) {
          final cmp = ratingOf(b).compareTo(ratingOf(a));
          return cmp != 0 ? cmp : reviewCountOf(b).compareTo(reviewCountOf(a));
        });
        break;
      case SortOption.mostReviewed:
        items.sort((a, b) {
          final cmp = reviewCountOf(b).compareTo(reviewCountOf(a));
          return cmp != 0 ? cmp : ratingOf(b).compareTo(ratingOf(a));
        });
        break;
      case SortOption.none:
        break;
    }
  }

  // ============================================================
  // FILTER & SORT — Tab Hoạt động tham quan
  // ============================================================

  /// Cập nhật bộ lọc cho tab "Hoạt động tham quan" và áp dụng lọc.
  /// Chỉ lọc theo các field có DỮ LIỆU THẬT từ backend overview:
  /// category, rating, status (giờ mở cửa), reviewCount.
  void updateActivityFilter(ActivityFilter filter) {
    state.mapOrNull(
      loaded: (s) {
        var result = s.overview.activities.toList();

        // 1. Lọc theo loại hình (chọn nhiều, rỗng = tất cả).
        // enum.name khớp đúng giá trị backend trả về (attractions,
        // culturalHistory, entertainment, nature).
        if (filter.categories.isNotEmpty) {
          result = result.where((a) {
            return filter.categories.any((c) => c.name == a.category);
          }).toList();
        }

        // 2. Lọc theo đánh giá tối thiểu
        if (filter.minRating != MinRating.all) {
          result =
              result.where((a) => a.rating >= filter.minRating.value).toList();
        }

        // 3. Chỉ hiện địa điểm đang mở cửa
        if (filter.openNowOnly) {
          result = result.where((a) => a.status.contains('Đang mở')).toList();
        }

        // 4. Sắp xếp
        _sortInPlace(
          result,
          filter.sortOption,
          ratingOf: (a) => a.rating,
          reviewCountOf: (a) => a.reviewCount,
        );

        emit(s.copyWith(activityFilter: filter, filteredActivities: result));
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

        // 1. Lọc theo đánh giá tối thiểu
        if (filter.minRating != MinRating.all) {
          result =
              result.where((r) => r.rating >= filter.minRating.value).toList();
        }

        // 2. Chỉ hiện nhà hàng đang mở cửa
        if (filter.openNowOnly) {
          result = result.where((r) => r.status.contains('Đang mở')).toList();
        }

        // 3. Sắp xếp
        _sortInPlace(
          result,
          filter.sortOption,
          ratingOf: (r) => r.rating,
          reviewCountOf: (r) => r.reviewCount,
        );

        emit(s.copyWith(restaurantFilter: filter, filteredRestaurants: result));
      },
    );
  }

  /// Đặt lại filter cho tab Nhà hàng về mặc định
  void resetRestaurantFilter() {
    updateRestaurantFilter(const RestaurantFilter());
  }

  // ============================================================
  // FILTER & SORT — Tab Khách sạn
  // ============================================================

  /// Cập nhật bộ lọc cho tab "Khách sạn" và áp dụng lọc.
  void updateHotelFilter(HotelFilter filter) {
    state.mapOrNull(
      loaded: (s) {
        var result = s.overview.hotels.toList();

        // 1. Lọc theo đánh giá tối thiểu
        if (filter.minRating != MinRating.all) {
          result =
              result.where((h) => h.rating >= filter.minRating.value).toList();
        }

        // 2. Sắp xếp
        _sortInPlace(
          result,
          filter.sortOption,
          ratingOf: (h) => h.rating,
          reviewCountOf: (h) => h.reviewCount,
        );

        emit(s.copyWith(hotelFilter: filter, filteredHotels: result));
      },
    );
  }

  /// Đặt lại filter cho tab Khách sạn về mặc định
  void resetHotelFilter() {
    updateHotelFilter(const HotelFilter());
  }
}

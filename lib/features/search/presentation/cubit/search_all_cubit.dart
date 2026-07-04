import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/filter_enums.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_results.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/search_all_usecase.dart';
import 'search_all_state.dart';

enum SearchResultSort {
  defaultOrder('Mặc định'),
  highestRated('Đánh giá cao nhất'),
  mostReviewed('Nhiều đánh giá nhất');

  final String label;
  const SearchResultSort(this.label);
}

class SearchAllCubit extends Cubit<SearchAllState> {
  final SearchAllUseCase _searchAll;

  SearchAllCubit(this._searchAll) : super(const SearchAllState.initial());

  MinRating _minRating = MinRating.all;
  bool _openNowOnly = false;
  int _priceRangeIndex = -1;
  SearchResultSort _sortOption = SearchResultSort.defaultOrder;

  MinRating get minRating => _minRating;
  bool get openNowOnly => _openNowOnly;
  int get priceRangeIndex => _priceRangeIndex;
  SearchResultSort get sortOption => _sortOption;

  Future<void> loadAll(String query) async {
    emit(const SearchAllState.loading());
    try {
      final results = await _searchAll(query);
      final items = <FlatSearchItem>[];

      for (final it in results.itineraries.data) {
        items.add(FlatSearchItem(
          type: SearchType.itinerary,
          id: it.id,
          data: it,
          city: results.cityById[it.id] ?? '',
        ));
      }
      for (final a in results.activities.data) {
        items.add(FlatSearchItem(
          type: SearchType.activity,
          id: a.id,
          data: a,
          city: results.cityById[a.id] ?? '',
        ));
      }
      for (final r in results.restaurants.data) {
        items.add(FlatSearchItem(
          type: SearchType.restaurant,
          id: r.id,
          data: r,
          city: results.cityById[r.id] ?? '',
        ));
      }
      for (final h in results.hotels.data) {
        items.add(FlatSearchItem(
          type: SearchType.hotel,
          id: h.id,
          data: h,
          city: results.cityById[h.id] ?? '',
        ));
      }

      final cities = items
          .map((i) => i.city)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      emit(SearchAllState.loaded(
        allItems: _sortByRank(items),
        cities: cities,
        query: query,
      ));
    } catch (_) {
      emit(const SearchAllState.error('Tải kết quả thất bại'));
    }
  }

  // ── Sort mặc định: rating cao + nhiều review lên đầu ──────────────────────
  // Bayesian weighted rating, đồng bộ công thức với backend
  // (SearchService.weightedRank): tránh 5.0★/1 review xếp trên 4.7★/500 review.
  static const double _rankMinReviews = 10; // m
  static const double _rankPriorRating = 3.0; // C

  static double _weightedRank(double rating, int reviewCount) {
    final v = reviewCount < 0 ? 0.0 : reviewCount.toDouble();
    final r = rating < 0 ? 0.0 : rating;
    if (v == 0 && r == 0) return 0;
    return (v / (v + _rankMinReviews)) * r +
        (_rankMinReviews / (v + _rankMinReviews)) * _rankPriorRating;
  }

  // Itinerary không có rating → xếp sau các địa điểm (rank -1),
  // giữ nguyên thứ tự backend trả về (mới nhất trước).
  static double _rankOf(FlatSearchItem item) {
    final data = item.data;
    if (data is CityActivity) {
      return _weightedRank(data.rating, data.reviewCount);
    }
    if (data is CityRestaurant) {
      return _weightedRank(data.rating, data.reviewCount);
    }
    if (data is CityHotel) {
      return _weightedRank(data.rating, data.reviewCount);
    }
    return -1;
  }

  // List.sort của Dart KHÔNG ổn định → tie-break bằng index gốc
  // để kết quả không nhảy thứ tự giữa các lần build.
  static List<FlatSearchItem> _sortByRank(List<FlatSearchItem> items) {
    final indexed = List.generate(items.length, (i) => i);
    final ranks = items.map(_rankOf).toList(growable: false);
    indexed.sort((a, b) {
      final cmp = ranks[b].compareTo(ranks[a]);
      return cmp != 0 ? cmp : a.compareTo(b);
    });
    return indexed.map((i) => items[i]).toList(growable: false);
  }

  void loadMore() {
    final s = state.mapOrNull(loaded: (s) => s);
    if (s == null) return;
    final allFiltered = filteredItems(state);
    if (s.displayedCount >= allFiltered.length) return;
    emit(s.copyWith(displayedCount: s.displayedCount + 10));
  }

  void applyTypeFilter(SearchType? type) {
    final s = state.mapOrNull(loaded: (s) => s);
    if (s == null) return;
    emit(s.copyWith(typeFilter: type, displayedCount: 10));
  }

  void applyCityFilter(String? city) {
    final s = state.mapOrNull(loaded: (s) => s);
    if (s == null) return;
    emit(s.copyWith(cityFilter: city, displayedCount: 10));
  }

  void applyAdvancedFilters({
    required MinRating minRating,
    required bool openNowOnly,
    required int priceRangeIndex,
    required SearchResultSort sortOption,
  }) {
    final s = state.mapOrNull(loaded: (s) => s);
    if (s == null) return;
    _minRating = minRating;
    _openNowOnly = openNowOnly;
    _priceRangeIndex = priceRangeIndex;
    _sortOption = sortOption;
    emit(s.copyWith(displayedCount: 10));
  }

  void applyFilters({
    required SearchType? type,
    required String? city,
    required MinRating minRating,
    required bool openNowOnly,
    required int priceRangeIndex,
    required SearchResultSort sortOption,
  }) {
    final s = state.mapOrNull(loaded: (s) => s);
    if (s == null) return;

    _minRating = minRating;
    _openNowOnly = openNowOnly;
    _priceRangeIndex = priceRangeIndex;
    _sortOption = sortOption;

    final next = s.copyWith(
      typeFilter: type,
      cityFilter: city,
      displayedCount: 10,
    );

    // Advanced filters live in cubit fields, not in Freezed state. If only
    // those fields changed, `next == s` and Bloc skips the emit; nudge the
    // visible state first so the result list rebuilds immediately.
    if (next == s) {
      emit(s.copyWith(displayedCount: 0));
    }
    emit(next);
  }

  bool get hasAdvancedFilter =>
      _minRating != MinRating.all ||
      _openNowOnly ||
      _priceRangeIndex >= 0 ||
      _sortOption != SearchResultSort.defaultOrder;

  static double ratingOf(FlatSearchItem item) {
    final data = item.data;
    if (data is CityActivity) return data.rating;
    if (data is CityRestaurant) return data.rating;
    if (data is CityHotel) return data.rating;
    return 0;
  }

  static int reviewCountOf(FlatSearchItem item) {
    final data = item.data;
    if (data is CityActivity) return data.reviewCount;
    if (data is CityRestaurant) return data.reviewCount;
    if (data is CityHotel) return data.reviewCount;
    return 0;
  }

  static String statusOf(FlatSearchItem item) {
    final data = item.data;
    if (data is CityActivity) return data.status;
    if (data is CityRestaurant) return data.status;
    if (data is CityHotel) return data.status;
    return '';
  }

  static double priceOf(FlatSearchItem item) {
    final data = item.data;
    if (data is CityHotel) return data.priceValue;
    return 0;
  }

  List<FlatSearchItem> filteredItems(SearchAllState state) {
    final s = state.mapOrNull(loaded: (s) => s);
    if (s == null) return [];
    final filtered = s.allItems.where((item) {
      if (s.typeFilter != null && item.type != s.typeFilter) return false;
      // items without city always pass city filter
      if (s.cityFilter != null && item.city.isNotEmpty && item.city != s.cityFilter) return false;
      if (_minRating != MinRating.all && ratingOf(item) < _minRating.value) {
        return false;
      }
      if (_openNowOnly &&
          !statusOf(item).toLowerCase().contains('đang mở')) {
        return false;
      }
      if (_priceRangeIndex >= 0) {
        if (item.type != SearchType.hotel) return false;
        final price = priceOf(item);
        if (price <= 0) return false;
        final ranges = SearchHotelPriceRange.values;
        if (_priceRangeIndex >= ranges.length) return false;
        final range = ranges[_priceRangeIndex];
        if (price < range.min) return false;
        if (range.max > 0 && price > range.max) return false;
      }
      return true;
    }).toList();
    switch (_sortOption) {
      case SearchResultSort.highestRated:
        filtered.sort((a, b) => ratingOf(b).compareTo(ratingOf(a)));
        break;
      case SearchResultSort.mostReviewed:
        filtered.sort((a, b) => reviewCountOf(b).compareTo(reviewCountOf(a)));
        break;
      case SearchResultSort.defaultOrder:
        break;
    }
    return filtered;
  }
}

enum SearchHotelPriceRange {
  under500k('Dưới 500K', 0, 500000),
  from500kTo1m('500K - 1 triệu', 500000, 1000000),
  from1mTo2m('1 - 2 triệu', 1000000, 2000000),
  above2m('Trên 2 triệu', 2000000, 0);

  final String label;
  final double min;
  final double max;
  const SearchHotelPriceRange(this.label, this.min, this.max);
}

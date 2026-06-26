import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_results.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/search_all_usecase.dart';
import 'search_all_state.dart';

class SearchAllCubit extends Cubit<SearchAllState> {
  final SearchAllUseCase _searchAll;

  SearchAllCubit(this._searchAll) : super(const SearchAllState.initial());

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
        allItems: items,
        cities: cities,
        query: query,
      ));
    } catch (_) {
      emit(const SearchAllState.error('Tải kết quả thất bại'));
    }
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

  List<FlatSearchItem> filteredItems(SearchAllState state) {
    final s = state.mapOrNull(loaded: (s) => s);
    if (s == null) return [];
    return s.allItems.where((item) {
      if (s.typeFilter != null && item.type != s.typeFilter) return false;
      // items without city always pass city filter
      if (s.cityFilter != null && item.city.isNotEmpty && item.city != s.cityFilter) return false;
      return true;
    }).toList();
  }
}

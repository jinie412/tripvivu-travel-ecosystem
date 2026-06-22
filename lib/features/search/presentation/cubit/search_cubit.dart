import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_state.dart';

import 'package:travel_advisor_mobile/core/services/activity_service.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/get_recent_searches.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/search_locations.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/save_recent_search.dart';

class SearchCubit extends Cubit<SearchState> {
  final GetRecentSearches _getRecentSearches;
  final SearchLocations _searchLocations;
  final SaveRecentSearch _saveRecentSearch;
  final ActivityService _activityService;
  Timer? _debounce;

  SearchCubit(
    this._getRecentSearches,
    this._searchLocations,
    this._saveRecentSearch,
    this._activityService,
  ) : super(const SearchState.initial());

  Future<void> loadRecentSearches() async {
    emit(const SearchState.loading());
    try {
      final recentSearches = await _getRecentSearches();
      emit(SearchState.loaded(recentSearches));
    } catch (e) {
      emit(const SearchState.error('Failed to load recent searches'));
    }
  }

  Future<void> onLocationSelected(SearchLocation location) async {
    await _saveRecentSearch(location);
  }

  void onSearchQueryChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      loadRecentSearches();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      emit(const SearchState.searching());
      try {
        final results = await _searchLocations(query);
        emit(SearchState.searchResults(results));
        // Log search action khi có kết quả trả về
        _activityService.trackSearch();
      } catch (e) {
        emit(const SearchState.error('Failed to search locations'));
      }
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

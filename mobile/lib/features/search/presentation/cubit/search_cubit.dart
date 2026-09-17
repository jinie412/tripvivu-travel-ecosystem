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

  List<SearchLocation> _cachedRecent = [];
  String _currentQuery = '';

  SearchCubit(
    this._getRecentSearches,
    this._searchLocations,
    this._saveRecentSearch,
    this._activityService,
  ) : super(const SearchState.initial());

  Future<void> loadRecentSearches({bool silent = false}) async {
    if (!silent) emit(const SearchState.loading());
    try {
      final recentSearches = await _getRecentSearches();
      _cachedRecent = recentSearches;
      if (silent) {
        // Only update UI if currently showing recent searches, not search results
        final isShowingRecent = state.maybeWhen(
          loaded: (_) => true,
          initial: () => true,
          orElse: () => false,
        );
        if (isShowingRecent) emit(SearchState.loaded(recentSearches));
      } else {
        emit(SearchState.loaded(recentSearches));
      }
    } catch (e) {
      if (!silent) emit(const SearchState.error('Failed to load recent searches'));
    }
  }

  Future<void> onLocationSelected(SearchLocation location) async {
    await _saveRecentSearch(location);
  }

  void onSearchQueryChanged(String query) {
    _debounce?.cancel();
    _currentQuery = query.trim();

    if (_currentQuery.isEmpty) {
      if (_cachedRecent.isNotEmpty) {
        emit(SearchState.loaded(_cachedRecent));
        loadRecentSearches(silent: true);
      } else {
        loadRecentSearches();
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final q = _currentQuery;
      emit(const SearchState.searching());
      try {
        final results = await _searchLocations(q);
        // Discard nếu user đã xóa/đổi query trong lúc đang fetch
        if (_currentQuery == q) {
          emit(SearchState.searchResults(results));
          _activityService.trackSearch();
        }
      } catch (e) {
        if (_currentQuery == q) {
          emit(const SearchState.error('Failed to search locations'));
        }
      }
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_recent_searches.dart';
import '../../domain/usecases/search_locations.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final GetRecentSearches _getRecentSearches;
  final SearchLocations _searchLocations;
  Timer? _debounce;

  SearchCubit(this._getRecentSearches, this._searchLocations) : super(const SearchState.initial());

  Future<void> loadRecentSearches() async {
    emit(const SearchState.loading());
    try {
      final recentSearches = await _getRecentSearches();
      emit(SearchState.loaded(recentSearches));
    } catch (e) {
      emit(const SearchState.error('Failed to load recent searches'));
    }
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

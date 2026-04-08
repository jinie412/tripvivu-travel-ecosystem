import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';

part 'search_state.freezed.dart';

@freezed
class SearchState with _$SearchState {
  const factory SearchState.initial() = _Initial;
  const factory SearchState.loading() = _Loading;
  const factory SearchState.loaded(List<SearchLocation> recentSearches) = _Loaded;
  const factory SearchState.searching() = _Searching;
  const factory SearchState.searchResults(List<SearchLocation> results) = _SearchResults;
  const factory SearchState.error(String message) = _Error;
}
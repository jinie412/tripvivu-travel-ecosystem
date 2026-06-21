import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_results.dart';

part 'search_all_state.freezed.dart';

@freezed
class SearchAllState with _$SearchAllState {
  const factory SearchAllState.initial() = _Initial;

  const factory SearchAllState.loading() = _Loading;

  const factory SearchAllState.loaded({
    required List<FlatSearchItem> allItems,
    required List<String> cities,
    required String query,
    SearchType? typeFilter,
    String? cityFilter,
    @Default(10) int displayedCount,
  }) = _Loaded;

  const factory SearchAllState.error(String message) = _Error;
}

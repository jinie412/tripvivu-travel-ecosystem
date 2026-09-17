import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_results.dart';

abstract class SearchRepository {
  Future<List<SearchLocation>> getRecentSearches();
  Future<List<SearchLocation>> searchLocations(String query);
  Future<void> saveRecentSearch(SearchLocation location);
  Future<SearchMultiResults> searchAll(String query);
  Future<SearchPageResult> searchByType(String query, SearchType type, int page, int limit);
}
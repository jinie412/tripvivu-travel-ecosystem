import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';
import 'package:travel_advisor_mobile/features/search/domain/repositories/search_repository.dart';

class SearchLocations {
  final SearchRepository repository;

  SearchLocations(this.repository);

  Future<List<SearchLocation>> call(String query) {
    return repository.searchLocations(query);
  }
}
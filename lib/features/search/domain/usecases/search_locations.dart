import '../entities/search_location.dart';
import '../repositories/search_repository.dart';

class SearchLocations {
  final SearchRepository repository;

  SearchLocations(this.repository);

  Future<List<SearchLocation>> call(String query) {
    return repository.searchLocations(query);
  }
}

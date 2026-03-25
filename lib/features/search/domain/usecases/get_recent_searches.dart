import '../entities/search_location.dart';
import '../repositories/search_repository.dart';

class GetRecentSearches {
  final SearchRepository repository;

  GetRecentSearches(this.repository);

  Future<List<SearchLocation>> call() {
    return repository.getRecentSearches();
  }
}

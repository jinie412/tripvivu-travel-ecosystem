import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';
import 'package:travel_advisor_mobile/features/search/domain/repositories/search_repository.dart';

class GetRecentSearches {
  final SearchRepository repository;

  GetRecentSearches(this.repository);

  Future<List<SearchLocation>> call() {
    return repository.getRecentSearches();
  }
}
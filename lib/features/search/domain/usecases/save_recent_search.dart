import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';
import 'package:travel_advisor_mobile/features/search/domain/repositories/search_repository.dart';

class SaveRecentSearch {
  final SearchRepository repository;

  SaveRecentSearch(this.repository);

  Future<void> call(SearchLocation location) {
    return repository.saveRecentSearch(location);
  }
}
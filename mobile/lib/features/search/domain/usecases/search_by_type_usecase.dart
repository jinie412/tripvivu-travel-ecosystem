import 'package:travel_advisor_mobile/features/search/domain/entities/search_results.dart';
import 'package:travel_advisor_mobile/features/search/domain/repositories/search_repository.dart';

class SearchByTypeUseCase {
  final SearchRepository _repository;
  const SearchByTypeUseCase(this._repository);

  Future<SearchPageResult> call(
          String query, SearchType type, int page, int limit) =>
      _repository.searchByType(query, type, page, limit);
}

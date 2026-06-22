import 'package:travel_advisor_mobile/features/search/domain/entities/search_results.dart';
import 'package:travel_advisor_mobile/features/search/domain/repositories/search_repository.dart';

class SearchAllUseCase {
  final SearchRepository _repository;
  const SearchAllUseCase(this._repository);

  Future<SearchMultiResults> call(String query) => _repository.searchAll(query);
}

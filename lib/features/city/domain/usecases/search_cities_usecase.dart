import 'package:travel_advisor_mobile/features/city/domain/entities/city_entity.dart';
import 'package:travel_advisor_mobile/features/city/domain/repositories/city_repository.dart';

class SearchCitiesUseCase {
  final CityRepository _repository;
  SearchCitiesUseCase(this._repository);

  Future<List<CityEntity>> call(String query) => _repository.searchCities(query);
}

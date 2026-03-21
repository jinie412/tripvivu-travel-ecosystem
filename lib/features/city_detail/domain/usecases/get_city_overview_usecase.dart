import '../entities/city_entities.dart';
import '../repositories/city_detail_repository.dart';

class GetCityOverviewUseCase {
  final CityDetailRepository repository;

  GetCityOverviewUseCase(this.repository);

  Future<CityOverview> call(String cityId) {
    return repository.getCityOverview(cityId);
  }
}

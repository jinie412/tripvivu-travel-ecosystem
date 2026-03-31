import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/repositories/city_detail_repository.dart';

class GetCityOverviewUseCase {
  final CityDetailRepository repository;

  GetCityOverviewUseCase(this.repository);

  Future<CityOverview> call(String cityId) {
    return repository.getCityOverview(cityId);
  }
}
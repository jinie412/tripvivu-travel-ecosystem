import '../entities/city_entities.dart';

abstract class CityDetailRepository {
  Future<CityOverview> getCityOverview(String cityId);
}

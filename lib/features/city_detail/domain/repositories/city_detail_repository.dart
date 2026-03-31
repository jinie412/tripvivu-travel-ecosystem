import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';

abstract class CityDetailRepository {
  Future<CityOverview> getCityOverview(String cityId);
}
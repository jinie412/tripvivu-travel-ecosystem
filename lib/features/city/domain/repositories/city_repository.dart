import 'package:travel_advisor_mobile/features/city/domain/entities/city_entity.dart';

abstract class CityRepository {
  Future<List<CityEntity>> searchCities(String query);
}

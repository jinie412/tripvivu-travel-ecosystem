import 'package:travel_advisor_mobile/features/city/data/datasources/city_datasource.dart';
import 'package:travel_advisor_mobile/features/city/domain/entities/city_entity.dart';
import 'package:travel_advisor_mobile/features/city/domain/repositories/city_repository.dart';

class CityRepositoryImpl implements CityRepository {
  final CityDataSource _dataSource;
  CityRepositoryImpl(this._dataSource);

  @override
  Future<List<CityEntity>> searchCities(String query) =>
      _dataSource.searchCities(query);
}

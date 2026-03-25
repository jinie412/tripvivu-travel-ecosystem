import '../../domain/entities/city_entities.dart';
import '../../domain/repositories/city_detail_repository.dart';
import '../datasources/city_detail_mock_data_source.dart' show CityDetailDataSource;
import '../models/city_models.dart';

class CityDetailRepositoryImpl implements CityDetailRepository {
  final CityDetailDataSource dataSource;

  CityDetailRepositoryImpl(this.dataSource);

  @override
  Future<CityOverview> getCityOverview(String cityId) async {
    final results = await Future.wait([
      dataSource.getItineraries(cityId),
      dataSource.getActivities(cityId),
      dataSource.getRestaurants(cityId),
      dataSource.getHotels(cityId),
    ]);

    final itineraries = results[0] as List<CityItineraryModel>;
    final activities = results[1] as List<CityActivityModel>;
    final restaurants = results[2] as List<CityRestaurantModel>;
    final hotels = results[3] as List<CityHotelModel>;

    return CityOverview(
      itineraries: itineraries.map((m) => m.toEntity()).toList(),
      activities: activities.map((m) => m.toEntity()).toList(),
      restaurants: restaurants.map((m) => m.toEntity()).toList(),
      hotels: hotels.map((m) => m.toEntity()).toList(),
    );
  }
}

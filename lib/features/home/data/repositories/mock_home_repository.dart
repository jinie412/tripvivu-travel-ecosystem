import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/data/datasources/home_datasource.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/hotel.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';
import 'package:travel_advisor_mobile/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDataSource _dataSource;
  HomeRepositoryImpl(this._dataSource);

  @override
  Future<List<TripSuggestion>> getSuggestions() async {
    final models = await _dataSource.getSuggestions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Destination>> getDestinations() async {
    final models = await _dataSource.getDestinations();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Hotel>> getHotels() async {
    final models = await _dataSource.getHotels();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<CityRestaurant>> getRestaurants() async {
    return _dataSource.getRestaurants();
  }
}
import '../../domain/entities/destination.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/trip_suggestion.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_datasource.dart';

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
}

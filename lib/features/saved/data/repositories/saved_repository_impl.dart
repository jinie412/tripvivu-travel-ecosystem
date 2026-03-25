import '../datasources/saved_mock_data_source.dart';
import '../../domain/repositories/saved_repository.dart';
import '../../../city_detail/domain/entities/city_entities.dart';
import '../../../home/domain/entities/destination.dart';

class SavedRepositoryImpl implements SavedRepository {
  final SavedMockDataSource dataSource;

  SavedRepositoryImpl({required this.dataSource});

  @override
  Future<List<CityItinerary>> getFavoriteItineraries() {
    return dataSource.getFavoriteItineraries();
  }

  @override
  Future<List<Destination>> getFavoritePlaces() {
    return dataSource.getFavoritePlaces();
  }
}

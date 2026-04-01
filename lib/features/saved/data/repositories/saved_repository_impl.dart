import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/saved_mock_data_source.dart';
import 'package:travel_advisor_mobile/features/saved/domain/repositories/saved_repository.dart';

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
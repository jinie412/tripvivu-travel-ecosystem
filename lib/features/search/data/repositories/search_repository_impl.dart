import '../../domain/entities/search_location.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_mock_data_source.dart';
import '../models/search_location_model.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchMockDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<SearchLocation>> getRecentSearches() async {
    try {
      final models = await remoteDataSource.getRecentSearches();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      // Return empty list if mock fails
      return [];
    }
  }

  @override
  Future<List<SearchLocation>> searchLocations(String query) async {
    try {
      final models = await remoteDataSource.searchLocations(query);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      return [];
    }
  }
}

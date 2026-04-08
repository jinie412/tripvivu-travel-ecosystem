import 'package:travel_advisor_mobile/features/search/data/datasources/search_mock_data_source.dart';
import 'package:travel_advisor_mobile/features/search/data/models/search_location_model.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';
import 'package:travel_advisor_mobile/features/search/domain/repositories/search_repository.dart';

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
// lib/features/search/data/repositories/search_repository_impl.dart

import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/search/data/datasources/search_remote_datasource.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_results.dart';
import 'package:travel_advisor_mobile/features/search/domain/repositories/search_repository.dart';
import 'package:travel_advisor_mobile/features/search/data/datasources/search_local_datasource.dart';
import 'package:travel_advisor_mobile/features/search/data/models/search_location_model.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;
  final SearchLocalDataSource localDataSource;

  SearchRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<SearchLocation>> getRecentSearches() async {
    final touristId = await AuthUtils.getCurrentUserId();
    if (touristId != null && touristId.isNotEmpty) {
      try {
        final models = await remoteDataSource.getRecentSearches(touristId);
        return models.map((m) => m.toEntity()).toList();
      } catch (_) {}
    }
    final models = await localDataSource.getRecentSearches();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SearchLocation>> searchLocations(String query) async {
    final models = await remoteDataSource.searchAutocomplete(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveRecentSearch(SearchLocation location) async {
    final model = SearchLocationModel(
      id: location.id,
      name: location.name,
      imageUrl: location.imageUrl,
      type: location.type,
    );
    await localDataSource.saveRecentSearch(model);
  }

  @override
  Future<SearchMultiResults> searchAll(String query) =>
      remoteDataSource.searchAll(query);

  @override
  Future<SearchPageResult> searchByType(
          String query, SearchType type, int page, int limit) =>
      remoteDataSource.searchByType(query, type, page, limit);
}
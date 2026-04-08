import 'package:travel_advisor_mobile/features/saved/data/datasources/collections_datasource.dart';
import 'package:travel_advisor_mobile/features/saved/domain/entities/favorite_itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/saved/domain/entities/favorite_place_entity.dart';
import 'package:travel_advisor_mobile/features/saved/domain/repositories/saved_repository.dart';

class SavedRepositoryImpl implements SavedRepository {
  final CollectionsDataSource dataSource;

  SavedRepositoryImpl({required this.dataSource});

  @override
  Future<List<FavoriteItineraryEntity>> getFavoriteItineraries({
    int page = 1,
    int limit = 5,
  }) async {
    final models = await dataSource.getFavoriteItineraries(page: page, limit: limit);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<FavoritePlaceEntity>> getFavoritePlaces({
    int page = 1,
    int limit = 5,
  }) async {
    final models = await dataSource.getFavoritePlaces(page: page, limit: limit);
    return models.map((model) => model.toEntity()).toList();
  }
}
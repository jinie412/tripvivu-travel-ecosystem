import 'package:travel_advisor_mobile/features/saved/domain/entities/favorite_place_entity.dart';
import 'package:travel_advisor_mobile/features/saved/domain/repositories/saved_repository.dart';

class GetFavoritePlacesUseCase {
  final SavedRepository repository;

  GetFavoritePlacesUseCase({required this.repository});

  Future<List<FavoritePlaceEntity>> call({
    int page = 1,
    int limit = 5,
  }) {
    return repository.getFavoritePlaces(page: page, limit: limit);
  }
}

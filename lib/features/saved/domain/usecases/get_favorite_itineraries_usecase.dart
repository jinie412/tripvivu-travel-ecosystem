import 'package:travel_advisor_mobile/features/saved/domain/entities/favorite_itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/saved/domain/repositories/saved_repository.dart';

class GetFavoriteItinerariesUseCase {
  final SavedRepository repository;

  GetFavoriteItinerariesUseCase({required this.repository});

  Future<List<FavoriteItineraryEntity>> call({
    int page = 1,
    int limit = 5,
  }) {
    return repository.getFavoriteItineraries(page: page, limit: limit);
  }
}

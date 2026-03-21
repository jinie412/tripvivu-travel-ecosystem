import '../entities/place_detail_entity.dart';
import '../repositories/place_repository.dart';

class GetPlaceDetailUseCase {
  final PlaceRepository repository;

  GetPlaceDetailUseCase(this.repository);

  Future<PlaceDetailEntity> call(String id) async {
    return await repository.getPlaceDetail(id);
  }
}

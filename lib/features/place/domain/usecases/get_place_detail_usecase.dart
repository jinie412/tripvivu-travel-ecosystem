import 'package:travel_advisor_mobile/features/place/domain/entities/place_detail_entity.dart';
import 'package:travel_advisor_mobile/features/place/domain/repositories/place_repository.dart';

class GetPlaceDetailUseCase {
  final PlaceRepository repository;

  GetPlaceDetailUseCase(this.repository);

  Future<PlaceDetailEntity> call(String id) async {
    return await repository.getPlaceDetail(id);
  }
}
import '../entities/place_detail_entity.dart';

abstract class PlaceRepository {
  Future<PlaceDetailEntity> getPlaceDetail(String id);
}

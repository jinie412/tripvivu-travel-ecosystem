import 'package:travel_advisor_mobile/features/place/domain/entities/place_detail_entity.dart';

abstract class PlaceRepository {
  Future<PlaceDetailEntity> getPlaceDetail(String id);
}
import 'package:travel_advisor_mobile/features/place/data/datasources/place_datasource.dart';
import 'package:travel_advisor_mobile/features/place/domain/entities/place_detail_entity.dart';
import 'package:travel_advisor_mobile/features/place/domain/repositories/place_repository.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  final PlaceDataSource dataSource;

  PlaceRepositoryImpl(this.dataSource);

  @override
  Future<PlaceDetailEntity> getPlaceDetail(String id) async {
    final model = await dataSource.getPlaceDetail(id);
    return model.toEntity();
  }
}
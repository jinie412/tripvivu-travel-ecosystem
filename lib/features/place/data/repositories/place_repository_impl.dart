import '../../domain/repositories/place_repository.dart';
import '../../domain/entities/place_detail_entity.dart';
import '../datasources/place_datasource.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  final PlaceDataSource dataSource;

  PlaceRepositoryImpl(this.dataSource);

  @override
  Future<PlaceDetailEntity> getPlaceDetail(String id) async {
    final model = await dataSource.getPlaceDetail(id);
    return model.toEntity();
  }
}

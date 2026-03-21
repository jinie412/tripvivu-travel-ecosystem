import '../../domain/entities/itinerary_entity.dart';
import '../../domain/entities/itinerary_summary.dart';
import '../../domain/entities/itinerary_detail_entity.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../datasources/itinerary_datasource.dart';

/// Implementation cụ thể của [ItineraryRepository].
///
/// Delegate mọi thao tác sang [ItineraryDataSource] và chuyển đổi
/// Model → Entity trước khi trả về cho tầng Domain.
class ItineraryRepositoryImpl implements ItineraryRepository {
  final ItineraryDataSource _dataSource;
  ItineraryRepositoryImpl(this._dataSource);

  @override
  Future<List<ItineraryEntity>> getItineraries({
    ItineraryStatus? status,
  }) async {
    final models = await _dataSource.getItineraries();
    final entities = models.map((m) => m.toEntity()).toList();

    // Lọc theo status nếu có.
    if (status != null) {
      return entities.where((e) => e.status == status).toList();
    }
    return entities;
  }

  @override
  Future<ItinerarySummary> getSummary() async {
    final models = await _dataSource.getItineraries();
    final entities = models.map((m) => m.toEntity()).toList();

    return ItinerarySummary(
      total: entities.length,
      completed:
          entities.where((e) => e.status == ItineraryStatus.completed).length,
      upcoming:
          entities.where((e) => e.status == ItineraryStatus.upcoming).length,
      draft: entities.where((e) => e.status == ItineraryStatus.draft).length,
    );
  }

  @override
  Future<void> deleteItinerary(String id) async {
    await _dataSource.deleteItinerary(id);
  }

  @override
  Future<ItineraryDetailEntity> getItineraryDetail(String id) async {
    final model = await _dataSource.getItineraryDetail(id);
    return model.toEntity();
  }
}

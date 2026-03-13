import '../entities/itinerary_entity.dart';
import '../repositories/itinerary_repository.dart';
import '../entities/itinerary_summary.dart';

/// UseCase: Lấy danh sách lịch trình (có thể lọc theo status).
class GetItinerariesUseCase {
  final ItineraryRepository _repository;
  GetItinerariesUseCase(this._repository);

  Future<List<ItineraryEntity>> call({ItineraryStatus? status}) {
    return _repository.getItineraries(status: status);
  }
}

/// UseCase: Lấy thống kê tổng quan.
class GetItinerarySummaryUseCase {
  final ItineraryRepository _repository;
  GetItinerarySummaryUseCase(this._repository);

  Future<ItinerarySummary> call() {
    return _repository.getSummary();
  }
}

/// UseCase: Xóa một lịch trình.
class DeleteItineraryUseCase {
  final ItineraryRepository _repository;
  DeleteItineraryUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.deleteItinerary(id);
  }
}

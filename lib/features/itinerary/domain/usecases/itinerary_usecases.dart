import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';

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

/// UseCase: Lấy chi tiết lịch trình.
class GetItineraryDetailUseCase {
  final ItineraryRepository _repository;
  GetItineraryDetailUseCase(this._repository);

  Future<ItineraryDetailEntity> call(String id) {
    return _repository.getItineraryDetail(id);
  }
}

/// UseCase: Cập nhật hoạt động/mốc thời gian của lịch trình.
class UpdateItineraryActivitiesUseCase {
  final ItineraryRepository _repository;
  UpdateItineraryActivitiesUseCase(this._repository);

  Future<void> call(String id, List<ItineraryDayEntity> days) {
    return _repository.updateItineraryActivities(id, days);
  }
}
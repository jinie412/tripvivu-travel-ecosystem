import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/customize_activity_response_model.dart';

/// UseCase: Lấy danh sách lịch trình (có thể lọc theo status).
class GetItinerariesUseCase {
  final ItineraryRepository _repository;
  GetItinerariesUseCase(this._repository);

  Future<List<ItineraryEntity>> call({ItineraryStatus? status, String? query}) {
    return _repository.getItineraries(status: status, query: query);
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

/// UseCase: Bật/tắt chế độ công khai.
class ToggleVisibilityUseCase {
  final ItineraryRepository _repository;
  ToggleVisibilityUseCase(this._repository);

  Future<void> call(String id, bool isPublic) {
    return _repository.toggleVisibility(id, isPublic);
  }
}

/// UseCase: Cập nhật tiêu đề/tên lịch trình.
class UpdateItineraryTitleUseCase {
  final ItineraryRepository _repository;
  UpdateItineraryTitleUseCase(this._repository);

  Future<void> call(String id, String title) {
    return _repository.updateItineraryTitle(id, title);
  }
}

/// UseCase: Cập nhật thông tin một hoạt động.
class UpdateActivityUseCase {
  final ItineraryRepository _repository;
  UpdateActivityUseCase(this._repository);

  Future<void> call(
    String itineraryId,
    String activityId, {
    String? arrivalTime,
    String? departureTime,
    double? actualCost,
    String? userNotes,
    bool? isLocked,
  }) {
    return _repository.updateActivity(
      itineraryId,
      activityId,
      arrivalTime: arrivalTime,
      departureTime: departureTime,
      actualCost: actualCost,
      userNotes: userNotes,
      isLocked: isLocked,
    );
  }
}

/// UseCase: Xóa một hoạt động khỏi lịch trình.
class DeleteActivityUseCase {
  final ItineraryRepository _repository;
  DeleteActivityUseCase(this._repository);

  Future<void> call(String itineraryId, String activityId) {
    return _repository.deleteActivity(itineraryId, activityId);
  }
}

/// UseCase: Thêm một địa điểm mới vào lịch trình
class AddActivityUseCase {
  final ItineraryRepository _repository;
  AddActivityUseCase(this._repository);

  Future<CustomizeActivityResponseModel> call(
    String itineraryId,
    int dayNumber,
    String placeId, {
    String? preferredTime,
    bool isLocked = false,
  }) {
    return _repository.addActivityToItinerary(
      itineraryId,
      dayNumber,
      placeId,
      preferredTime: preferredTime,
      isLocked: isLocked,
    );
  }
}

/// UseCase: Thay thế một địa điểm bằng địa điểm khác
class ReplaceActivityUseCase {
  final ItineraryRepository _repository;
  ReplaceActivityUseCase(this._repository);

  Future<CustomizeActivityResponseModel> call(
    String itineraryId,
    String activityId,
    String newPlaceId,
  ) {
    return _repository.replaceActivityInItinerary(
      itineraryId,
      activityId,
      newPlaceId,
    );
  }
}

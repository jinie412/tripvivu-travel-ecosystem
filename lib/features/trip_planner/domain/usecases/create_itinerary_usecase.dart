import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';

class CreateItineraryResult {
  final String itineraryId;
  final String? gaItineraryId;
  const CreateItineraryResult({required this.itineraryId, this.gaItineraryId});
  bool get isCompare => gaItineraryId != null && gaItineraryId!.isNotEmpty;
}

/// Number of days the user chose to spend in one detected region, from the
/// region-allocation wizard (see RegionAllocationRequiredException).
class RegionAllocationInput {
  final List<String> placeIds;
  final int days;

  const RegionAllocationInput({required this.placeIds, required this.days});

  Map<String, dynamic> toJson() => {'placeIds': placeIds, 'days': days};
}

class CreateItineraryParams {
  final String userId;
  final String tripType;
  final String departureLocationId;
  final String destinationLocationId;
  final String transportMode;
  final String startDate;
  final String endDate;
  final String dailyStartTime;
  final String dailyEndTime;
  final String tripIntent;
  final int adultCount;
  final int childCount;
  final double budget;
  final List<String> foodPreferences;
  // [TRIP_NAME_INPUT] Tên chuyến đi do user nhập ở Bước 3
  final String? tripName;
  // Gửi true khi user đã xác nhận tiếp tục với lịch trình vượt ngân sách đề
  // xuất (sau khi nhận cảnh báo BUDGET_CONFIRMATION_REQUIRED).
  final bool proceedWithOverBudget;
  // Kết quả wizard phân bổ vùng (sau khi nhận REGION_ALLOCATION_REQUIRED) —
  // số ngày user chọn cho từng vùng địa lý đã phát hiện. Rỗng ở lần gọi đầu
  // tiên, backend sẽ luôn trả về REGION_ALLOCATION_REQUIRED cho tới khi có.
  final List<RegionAllocationInput> regionAllocations;
  // Token nhận từ BudgetConfirmationRequiredException — gửi lại ở request
  // "Dùng mức đề xuất" để backend dùng thẳng plan đã tính sẵn, bỏ qua chạy
  // lại thuật toán lập lịch trình.
  final String? confirmToken;

  const CreateItineraryParams({
    required this.userId,
    required this.tripType,
    required this.departureLocationId,
    required this.destinationLocationId,
    required this.transportMode,
    required this.startDate,
    required this.endDate,
    required this.dailyStartTime,
    required this.dailyEndTime,
    required this.tripIntent,
    required this.adultCount,
    required this.childCount,
    required this.budget,
    required this.foodPreferences,
    this.tripName,
    this.proceedWithOverBudget = false,
    this.regionAllocations = const [],
    this.confirmToken,
  });

  CreateItineraryParams copyWith({
    double? budget,
    bool? proceedWithOverBudget,
    List<RegionAllocationInput>? regionAllocations,
    String? confirmToken,
  }) {
    return CreateItineraryParams(
      userId: userId,
      tripType: tripType,
      departureLocationId: departureLocationId,
      destinationLocationId: destinationLocationId,
      transportMode: transportMode,
      startDate: startDate,
      endDate: endDate,
      dailyStartTime: dailyStartTime,
      dailyEndTime: dailyEndTime,
      tripIntent: tripIntent,
      adultCount: adultCount,
      childCount: childCount,
      budget: budget ?? this.budget,
      foodPreferences: foodPreferences,
      tripName: tripName,
      proceedWithOverBudget:
          proceedWithOverBudget ?? this.proceedWithOverBudget,
      regionAllocations: regionAllocations ?? this.regionAllocations,
      confirmToken: confirmToken ?? this.confirmToken,
    );
  }
}

class CreateItineraryUseCase {
  final ItineraryRepository _repository;
  CreateItineraryUseCase(this._repository);

  Future<CreateItineraryResult> call(CreateItineraryParams params) =>
      _repository.createItinerary(params);
}

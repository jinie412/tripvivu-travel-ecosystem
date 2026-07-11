import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';

class CreateItineraryRequestModel {
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
  // [TRIP_NAME_INPUT] Ánh xạ sang trường description trong CreateItineraryDto
  final String? description;
  // Gửi true khi user đã xác nhận tiếp tục với lịch trình vượt ngân sách đề
  // xuất (sau khi nhận cảnh báo BUDGET_CONFIRMATION_REQUIRED).
  final bool proceedWithOverBudget;
  // Kết quả wizard phân bổ vùng (sau khi nhận REGION_ALLOCATION_REQUIRED).
  final List<RegionAllocationInput> regionAllocations;

  const CreateItineraryRequestModel({
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
    this.description,
    this.proceedWithOverBudget = false,
    this.regionAllocations = const [],
  });

  static const _foodPrefMap = {
    'Đặc sản địa phương': 'LOCAL',
    'Hải sản': 'SEAFOOD',
    'Món chay': 'VEGETARIAN',
    'Đường phố': 'STREET',
    'Nhà hàng cao cấp': 'FINE_DINING',
  };

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'tripType': tripType,
    'departureLocationId': departureLocationId,
    'destinationLocationId': destinationLocationId,
    'transportMode': transportMode,
    'startDate': startDate,
    'endDate': endDate,
    'dailyStartTime': dailyStartTime,
    'dailyEndTime': dailyEndTime,
    'tripIntent': tripIntent,
    'adultCount': adultCount,
    'childCount': childCount,
    'budget': budget,
    'foodPreferences': foodPreferences
        .map((p) => _foodPrefMap[p] ?? p)
        .toList(),
    // [TRIP_NAME_INPUT] Chỉ gửi khi user đã nhập tên
    if (description != null && description!.isNotEmpty)
      'description': description,
    if (proceedWithOverBudget) 'proceedWithOverBudget': true,
    if (regionAllocations.isNotEmpty)
      'regionAllocations': regionAllocations.map((r) => r.toJson()).toList(),
  };
}

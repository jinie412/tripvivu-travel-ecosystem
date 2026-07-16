import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_activity_entity.freezed.dart';

enum ActivityStatus { chuaDi, dangDi, daDi, diQua }

@freezed
class ItineraryActivityEntity with _$ItineraryActivityEntity {
  const factory ItineraryActivityEntity({
    required String id,
    String? placeId,
    required String title,
    required String startTime,
    required String endTime,
    required String locationName,
    required String address,
    required String imageUrl,
    @Default(0) double price,
    @Default(0) double transportCost,
    @Default('VNĐ') String currency,
    String? transportInfo,
    // Quãng đường/thời gian di chuyển ĐẾN hoạt động tiếp theo (transitToNext),
    // dùng để cộng dồn "km di chuyển"/"giờ di chuyển" cho card tổng quan
    // ngày — transportInfo chỉ là chuỗi hiển thị, không parse ngược được.
    double? transitDistanceKm,
    int? transitDurationMinutes,
    @Default(false) bool isFree,
    String? category, // e.g. "Cà phê", "Tham quan"
    // travel.places.slot_type — cùng nguồn phân loại dùng lúc tạo lịch trình
    // (attraction | restaurant | cafe | entertainment | ...), dùng để nhận diện
    // địa điểm ăn trưa kết hợp với khung giờ, thay vì đoán qua từ khóa category.
    String? placeType,

    // Geographical coordinates
    double? latitude,
    double? longitude,

    // Rating and Reviews
    double? rating,
    int? reviewCount,

    // Status
    @Default(ActivityStatus.chuaDi) ActivityStatus status,
    String? openHourCompressed,
  }) = _ItineraryActivityEntity;
}

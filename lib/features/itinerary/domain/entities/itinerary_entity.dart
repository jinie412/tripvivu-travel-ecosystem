import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_entity.freezed.dart';

/// Trạng thái của một lịch trình.
enum ItineraryStatus { upcoming, ongoing, completed, draft }

/// Entity chính — đại diện cho một lịch trình du lịch.
///
/// Được sử dụng xuyên suốt tầng Domain & Presentation.
/// Tầng Data sẽ map từ [ItineraryModel] sang [ItineraryEntity] thông qua `toEntity()`.
@freezed
class ItineraryEntity with _$ItineraryEntity {
  const factory ItineraryEntity({
    /// Mã định danh duy nhất.
    required String id,

    /// Tên lịch trình. VD: "Sài Gòn 3N2Đ"
    required String title,

    /// URL ảnh đại diện.
    String? imageUrl,

    /// Ngày bắt đầu chuyến đi.
    DateTime? startDate,

    /// Ngày kết thúc chuyến đi.
    DateTime? endDate,

    /// Tổng chi phí dự kiến (VNĐ). VD: 5200000
    @Default(0) double estimatedCost,

    /// Đơn vị tiền tệ. VD: "VNĐ"
    @Default('VNĐ') String currency,

    /// Số ngày. VD: 3
    @Default(1) int durationDays,

    /// Tiến độ hoàn thành (0.0 → 1.0). Dùng cho card "Sắp đi".
    @Default(0.0) double progress,

    /// Trạng thái: upcoming, completed, draft.
    @Default(ItineraryStatus.draft) ItineraryStatus status,

    /// Đánh giá sau chuyến đi (chỉ khi status == completed). VD: 4.8
    double? rating,

    /// Màu placeholder khi ảnh chưa tải xong.
    @Default(0xFF90CAF9) int placeholderColor,
  }) = _ItineraryEntity;
}

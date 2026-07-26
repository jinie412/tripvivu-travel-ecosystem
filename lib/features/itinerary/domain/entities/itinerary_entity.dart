import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_entity.freezed.dart';

/// Trạng thái của một lịch trình.
enum ItineraryStatus { upcoming, ongoing, completed, uncompleted, draft }

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

    /// Chi phí dự kiến TÍNH THEO 1 NGƯỜI LỚN (VNĐ). VD: 5200000
    @Default(0) double estimatedCost,

    /// Tổng số người của chuyến đi.
    @Default(1) int participantCount,

    /// Số người lớn / trẻ em trong chuyến đi.
    @Default(1) int adultCount,
    @Default(0) int childCount,

    /// Tổng chi phí ước tính cho CẢ NHÓM — tính tươi ở backend từ
    /// estimatedCost * adultCount + estimatedCost * childPriceRatio *
    /// childCount, không lưu trữ, không dùng để suy ngược lại estimatedCost.
    @Default(0) double estimatedCostForGroup,

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

    /// Số địa điểm đã ghé thăm.
    @Default(0) int visitedLocations,

    /// Tổng số địa điểm trong lịch trình.
    @Default(0) int totalLocations,

    /// Màu placeholder khi ảnh chưa tải xong.
    @Default(0xFF90CAF9) int placeholderColor,

    /// GPS tracking đang bật trên thiết bị (nguồn gốc từ cột tracking_active trong DB).
    /// Khác với [status]: status = vòng đời chuyến đi; trackingActive = tracking có đang chạy không.
    @Default(false) bool trackingActive,

    /// true khi user hiện tại là chủ lịch trình; false với lịch trình được chia sẻ.
    @Default(true) bool isOwner,

    /// Danh sách ảnh địa điểm trong lịch trình (tối đa 5, từ place_images của API).
    @Default([]) List<String> placeImages,
  }) = _ItineraryEntity;
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_summary.freezed.dart';

/// Thống kê tổng quan lịch trình — hiển thị trên lưới 2×2.
@freezed
class ItinerarySummary with _$ItinerarySummary {
  const factory ItinerarySummary({
    /// Tổng số lịch trình.
    @Default(0) int total,

    /// Số lịch trình đã hoàn thành.
    @Default(0) int completed,

    /// Số lịch trình sắp đi.
    @Default(0) int upcoming,

    /// Số lịch trình đang diễn ra.
    @Default(0) int ongoing,

    /// Số lịch trình đang tạo (nháp).
    @Default(0) int draft,
  }) = _ItinerarySummary;
}
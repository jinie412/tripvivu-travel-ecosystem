import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_enums.freezed.dart';

// ============================================================
// ENUM — Các giá trị filter cho từng tab
//
// Chỉ giữ những filter mà backend /explore/cities/:id/overview có DỮ LIỆU
// THẬT: category của activity, status giờ mở cửa, rating, reviewCount.
// Các filter mock cũ (khoảng giá, quận/huyện mẫu, món ăn, tiện ích, loại
// lưu trú...) được backup tại docs/deprecated/city_detail_filter_mock/ —
// khôi phục lại khi backend có data tương ứng.
// ============================================================

/// Loại hình hoạt động tham quan — khớp đúng field `category` backend trả về
/// (explore.service.ts → mapActivityEntityCategory):
/// attractions | culturalHistory | entertainment | nature
enum ActivityCategory {
  attractions('Tham quan & Khám phá'),
  culturalHistory('Văn hóa & Di sản'),
  entertainment('Giải trí & Vui chơi'),
  nature('Thư giãn & Thể thao');

  final String label;
  const ActivityCategory(this.label);
}

/// Mức đánh giá tối thiểu (dùng chung cho cả 3 tab)
enum MinRating {
  all(0, 'Tất cả'),
  threePlus(3.0, 'Từ 3.0 ★'),
  threeHalfPlus(3.5, 'Từ 3.5 ★'),
  fourPlus(4.0, 'Từ 4.0 ★'),
  fourHalfPlus(4.5, 'Từ 4.5 ★');

  final double value;
  final String label;
  const MinRating(this.value, this.label);
}

/// Tùy chọn sắp xếp (dùng chung cho tất cả tab)
enum SortOption {
  none('Mặc định'),
  highestRated('Đánh giá cao nhất'),
  mostReviewed('Nhiều đánh giá nhất');

  final String label;
  const SortOption(this.label);
}

// ============================================================
// FILTER STATE — Lưu trạng thái filter cho mỗi tab
// ============================================================

/// Bộ lọc cho tab "Hoạt động tham quan"
@freezed
class ActivityFilter with _$ActivityFilter {
  const factory ActivityFilter({
    /// Các loại hình đã chọn (chọn nhiều). Rỗng = tất cả.
    @Default({}) Set<ActivityCategory> categories,

    /// Đánh giá tối thiểu
    @Default(MinRating.all) MinRating minRating,

    /// Chỉ hiện địa điểm đang mở cửa
    @Default(false) bool openNowOnly,

    /// Tùy chọn sắp xếp
    @Default(SortOption.none) SortOption sortOption,
  }) = _ActivityFilter;
}

/// Bộ lọc cho tab "Nhà hàng"
@freezed
class RestaurantFilter with _$RestaurantFilter {
  const factory RestaurantFilter({
    /// Đánh giá tối thiểu
    @Default(MinRating.all) MinRating minRating,

    /// Chỉ hiện nhà hàng đang mở cửa
    @Default(false) bool openNowOnly,

    /// Tùy chọn sắp xếp
    @Default(SortOption.none) SortOption sortOption,
  }) = _RestaurantFilter;
}

/// Bộ lọc cho tab "Khách sạn"
@freezed
class HotelFilter with _$HotelFilter {
  const factory HotelFilter({
    /// Đánh giá tối thiểu
    @Default(MinRating.all) MinRating minRating,

    /// Tùy chọn sắp xếp
    @Default(SortOption.none) SortOption sortOption,
  }) = _HotelFilter;
}

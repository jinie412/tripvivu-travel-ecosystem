import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_enums.freezed.dart';

// ============================================================
// ENUM — Các giá trị filter cho từng tab
// ============================================================

/// Loại hình hoạt động tham quan
enum ActivityCategory {
  culturalHistory('Văn hóa/Lịch sử'),
  nature('Thiên nhiên'),
  entertainment('Giải trí'),
  restaurant('Nhà hàng'),
  attractions('Điểm tham quan'),
  cafe('Quán cà phê'),
  photoSpot('Điểm chụp ảnh'),
  museum('Bảo tàng');

  final String label;
  const ActivityCategory(this.label);
}

/// Khoảng giá hoạt động tham quan
enum ActivityPriceType {
  all('Tất cả'),
  free('Miễn phí'),
  paid('Trả phí');

  final String label;
  const ActivityPriceType(this.label);
}

/// Danh mục nhà hàng
enum RestaurantCuisine {
  vietnamese('Món Việt'),
  foreign('Món ngoại'),
  vegetarian('Đồ chay');

  final String label;
  const RestaurantCuisine(this.label);
}

/// Mức giá nhà hàng
enum RestaurantPriceLevel {
  all('Tất cả'),
  budget('Bình dân'),
  midRange('Trung cấp'),
  premium('Sang trọng');

  final String label;
  const RestaurantPriceLevel(this.label);
}

/// Tiện ích nhà hàng
enum RestaurantAmenity {
  parking('Có chỗ đậu xe'),
  airCon('Có điều hòa'),
  kidFriendly('Phù hợp cho trẻ em');

  final String label;
  const RestaurantAmenity(this.label);
}

/// Loại hình lưu trú khách sạn
enum AccommodationType {
  hotel('Khách sạn'),
  homestay('Homestay'),
  resort('Resort'),
  apartment('Căn hộ'),
  guesthouse('Nhà nghỉ');

  final String label;
  const AccommodationType(this.label);
}

/// Tiện nghi khách sạn
enum HotelAmenity {
  pool('Hồ bơi'),
  freeWifi('Wifi miễn phí'),
  breakfast('Có bữa sáng'),
  gym('Phòng gym');

  final String label;
  const HotelAmenity(this.label);
}

/// Tùy chọn sắp xếp (dùng chung cho tất cả tab)
enum SortOption {
  none('Mặc định'),
  mostPopular('Phổ biến nhất'),
  highestRated('Đánh giá cao nhất'),
  cheapest('Giá rẻ nhất');

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

    /// Khoảng giá đã chọn (chọn 1)
    @Default(ActivityPriceType.all) ActivityPriceType priceType,

    /// Quận/Huyện đã chọn. null = tất cả.
    @Default(null) String? district,

    /// Tùy chọn sắp xếp
    @Default(SortOption.none) SortOption sortOption,
  }) = _ActivityFilter;
}

/// Bộ lọc cho tab "Nhà hàng"
@freezed
class RestaurantFilter with _$RestaurantFilter {
  const factory RestaurantFilter({
    /// Danh mục đã chọn (chọn nhiều). Rỗng = tất cả.
    @Default({}) Set<RestaurantCuisine> cuisines,

    /// Mức giá đã chọn (chọn 1)
    @Default(RestaurantPriceLevel.all) RestaurantPriceLevel priceLevel,

    /// Tiện ích đã chọn (chọn nhiều)
    @Default({}) Set<RestaurantAmenity> amenities,

    /// Tùy chọn sắp xếp
    @Default(SortOption.none) SortOption sortOption,
  }) = _RestaurantFilter;
}

/// Bộ lọc cho tab "Khách sạn"
@freezed
class HotelFilter with _$HotelFilter {
  const factory HotelFilter({
    /// Giá tối thiểu (VNĐ). 0 = không giới hạn dưới.
    @Default(0) double minPrice,

    /// Giá tối đa (VNĐ). 0 = không giới hạn trên.
    @Default(0) double maxPrice,

    /// Loại hình lưu trú đã chọn (chọn nhiều). Rỗng = tất cả.
    @Default({}) Set<AccommodationType> accommodationTypes,

    /// Tiện nghi đã chọn (chọn nhiều)
    @Default({}) Set<HotelAmenity> amenities,

    /// Tùy chọn sắp xếp
    @Default(SortOption.none) SortOption sortOption,
  }) = _HotelFilter;
}

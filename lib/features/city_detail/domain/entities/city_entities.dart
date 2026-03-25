import 'package:freezed_annotation/freezed_annotation.dart';

part 'city_entities.freezed.dart';

@freezed
class CityItinerary with _$CityItinerary {
  const factory CityItinerary({
    required String id,
    required String title,
    required String authorName,
    required String authorAvatar,
    required String imageUrl,
    required String duration, // e.g., "3 NGÀY"
    required String views,
    required String likes,
    @Default('') String location,
  }) = _CityItinerary;
}

@freezed
class CityActivity with _$CityActivity {
  const factory CityActivity({
    required String id,
    required String title,
    required String imageUrl,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    @Default('') String address,
    @Default('') String status, // e.g., "Đang mở cửa"
    @Default(false) bool isFavorite,
  }) = _CityActivity;
}

@freezed
class CityRestaurant with _$CityRestaurant {
  const factory CityRestaurant({
    required String id,
    required String name,
    required String imageUrl,
    required double rating,
    required int reviewCount,
    @Default('') String address,
    @Default('') String status, // e.g., "Đang mở cửa"
    @Default(false) bool isFavorite,
  }) = _CityRestaurant;
}

@freezed
class CityHotel with _$CityHotel {
  const factory CityHotel({
    required String id,
    required String name,
    required String imageUrl,
    required double rating,
    required int reviewCount,
    required String price, // e.g., "5.450.000đ"
    @Default(false) bool isFavorite,
  }) = _CityHotel;
}

@freezed
class CityOverview with _$CityOverview {
  const factory CityOverview({
    required List<CityItinerary> itineraries,
    required List<CityActivity> activities,
    required List<CityRestaurant> restaurants,
    required List<CityHotel> hotels,
  }) = _CityOverview;
}

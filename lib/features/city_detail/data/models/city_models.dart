import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';

part 'city_models.freezed.dart';
part 'city_models.g.dart';

@freezed
class CityItineraryModel with _$CityItineraryModel {
  const factory CityItineraryModel({
    @Default('') String id,
    @Default('') String title,
    @Default('') String authorName,
    @Default('') String authorAvatar,
    @Default('') String imageUrl,
    @Default('') String duration,
    @Default('') String views,
    @Default('') String likes,
  }) = _CityItineraryModel;

  factory CityItineraryModel.fromJson(Map<String, dynamic> json) =>
      _$CityItineraryModelFromJson(json);
}

extension CityItineraryModelX on CityItineraryModel {
  CityItinerary toEntity() => CityItinerary(
    id: id,
    title: title,
    authorName: authorName,
    authorAvatar: authorAvatar,
    imageUrl: imageUrl,
    duration: duration,
    views: views,
    likes: likes,
  );
}

@freezed
class CityActivityModel with _$CityActivityModel {
  const factory CityActivityModel({
    @Default('') String id,
    @Default('') String name,
    @Default('') String imageUrl,

    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    @Default('') String address,
    @Default('') String status,
    @Default(false) bool isFavorite,

    // === Filter fields ===
    @Default('') String category,
    @Default('') String priceType,
    @Default('') String district,
  }) = _CityActivityModel;

  factory CityActivityModel.fromJson(Map<String, dynamic> json) =>
      _$CityActivityModelFromJson(json);
}


extension CityActivityModelX on CityActivityModel {
  CityActivity toEntity() => CityActivity(
    id: id,
    name: name,
    imageUrl: imageUrl,
    rating: rating,
    reviewCount: reviewCount,
    address: address,
    status: status,
    isFavorite: isFavorite,
    category: category,
    priceType: priceType,
    district: district,
  );
}

@freezed
class CityRestaurantModel with _$CityRestaurantModel {
  const factory CityRestaurantModel({
    @Default('') String id,
    @Default('') String name,
    @Default('') String imageUrl,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    @Default('') String address,
    @Default('') String status,
    @Default(false) bool isFavorite,
    @Default('') String cuisine,
    @Default('') String priceLevel,
    @Default([]) List<String> amenities,
  }) = _CityRestaurantModel;

  factory CityRestaurantModel.fromJson(Map<String, dynamic> json) =>
      _$CityRestaurantModelFromJson(json);
}


extension CityRestaurantModelX on CityRestaurantModel {
  CityRestaurant toEntity() => CityRestaurant(
    id: id,
    name: name,
    imageUrl: imageUrl,
    rating: rating,
    reviewCount: reviewCount,
    address: address,
    status: status,
    isFavorite: isFavorite,
    cuisine: cuisine,
    priceLevel: priceLevel,
    amenities: amenities,
  );
}

@freezed
class CityHotelModel with _$CityHotelModel {
  const factory CityHotelModel({
    @Default('') String id,
    @Default('') String name,
    @Default('') String imageUrl,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    @Default('') String address,
    @Default('') String price,
    @Default(false) bool isFavorite,

    // === Filter fields ===
    @Default(0) int starRating,
    @Default(0.0) double priceValue,
    @Default('') String accommodationType,
    @Default([]) List<String> amenities,
  }) = _CityHotelModel;

  factory CityHotelModel.fromJson(Map<String, dynamic> json) =>
      _$CityHotelModelFromJson(json);
}


extension CityHotelModelX on CityHotelModel {
  CityHotel toEntity() {
    return CityHotel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      rating: rating,
      reviewCount: reviewCount,
      address: address,
      price: price,
      isFavorite: isFavorite,
      starRating: starRating,
      priceValue: priceValue,
      accommodationType: accommodationType,
      amenities: amenities,
    );
  }
}

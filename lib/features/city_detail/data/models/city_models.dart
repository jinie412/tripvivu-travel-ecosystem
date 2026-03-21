import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/city_entities.dart';

part 'city_models.freezed.dart';
part 'city_models.g.dart';

@freezed
class CityItineraryModel with _$CityItineraryModel {
  const factory CityItineraryModel({
    required String id,
    required String title,
    required String authorName,
    required String authorAvatar,
    required String imageUrl,
    required String duration,
    required String views,
    required String likes,
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
    required String id,
    required String title,
    required String imageUrl,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    @Default('') String address,
    @Default('') String status,
    @Default(false) bool isFavorite,
  }) = _CityActivityModel;

  factory CityActivityModel.fromJson(Map<String, dynamic> json) =>
      _$CityActivityModelFromJson(json);
}

extension CityActivityModelX on CityActivityModel {
  CityActivity toEntity() => CityActivity(
        id: id,
        title: title,
        imageUrl: imageUrl,
        rating: rating,
        reviewCount: reviewCount,
        address: address,
        status: status,
        isFavorite: isFavorite,
      );
}

@freezed
class CityRestaurantModel with _$CityRestaurantModel {
  const factory CityRestaurantModel({
    required String id,
    required String name,
    required String imageUrl,
    required double rating,
    required int reviewCount,
    @Default('') String address,
    @Default('') String status,
    @Default(false) bool isFavorite,
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
      );
}

@freezed
class CityHotelModel with _$CityHotelModel {
  const factory CityHotelModel({
    required String id,
    required String name,
    required String imageUrl,
    required double rating,
    required int reviewCount,
    required String price,
    @Default(false) bool isFavorite,
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
      price: price,
      isFavorite: isFavorite,
    );
  }
}

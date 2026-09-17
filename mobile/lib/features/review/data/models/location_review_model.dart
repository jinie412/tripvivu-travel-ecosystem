import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:travel_advisor_mobile/features/review/domain/entities/location_review_entity.dart';

part 'location_review_model.freezed.dart';
part 'location_review_model.g.dart';

@freezed
class LocationReviewModel with _$LocationReviewModel {
  const factory LocationReviewModel({
    required String id,
    required String name,
    required String imageUrl,
    required int day,
    String? placeId,
    String? categoryId,
    @Default(false) bool isVisited,
    @Default(false) bool hasReview,
    double? rating,
    String? reviewText,
  }) = _LocationReviewModel;

  factory LocationReviewModel.fromJson(Map<String, dynamic> json) =>
      _$LocationReviewModelFromJson(json);

  const LocationReviewModel._();

  LocationReviewEntity toEntity() => LocationReviewEntity(
        id: id,
        name: name,
        imageUrl: imageUrl,
        day: day,
        placeId: placeId,
        categoryId: categoryId,
        isVisited: isVisited,
        hasReview: hasReview,
        rating: rating,
        reviewText: reviewText,
      );
}
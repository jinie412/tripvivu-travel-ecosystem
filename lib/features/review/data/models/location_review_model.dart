import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/location_review_entity.dart';

part 'location_review_model.freezed.dart';
part 'location_review_model.g.dart';

@freezed
class LocationReviewModel with _$LocationReviewModel {
  const factory LocationReviewModel({
    required String id,
    required String name,
    required String imageUrl,
    required int day,
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
        rating: rating,
        reviewText: reviewText,
      );
}

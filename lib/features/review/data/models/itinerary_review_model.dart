import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/itinerary_review_entity.dart';
import 'location_review_model.dart';

part 'itinerary_review_model.freezed.dart';
part 'itinerary_review_model.g.dart';

@freezed
class ItineraryReviewModel with _$ItineraryReviewModel {
  const factory ItineraryReviewModel({
    required String id,
    required String title,
    required String imageUrl,
    required String dateRange,
    required String status,
    required List<LocationReviewModel> locations,
  }) = _ItineraryReviewModel;

  factory ItineraryReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ItineraryReviewModelFromJson(json);

  const ItineraryReviewModel._();

  ItineraryReviewEntity toEntity() => ItineraryReviewEntity(
        id: id,
        title: title,
        imageUrl: imageUrl,
        dateRange: dateRange,
        status: status,
        locations: locations.map((e) => e.toEntity()).toList(),
      );
}

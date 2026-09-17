import 'package:json_annotation/json_annotation.dart';

import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';

part 'destination_model.g.dart';

@JsonSerializable()
class DestinationModel {
  final String id;
  final String name;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'placeholder_color')
  final int placeholderColor;
  @JsonKey(name: 'rating')
  final double averageRating;
  @JsonKey(name: 'review_count')
  final int reviewCount;

  const DestinationModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.placeholderColor = 0xFF4A8C5C,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) =>
      _$DestinationModelFromJson(json);

  Map<String, dynamic> toJson() => _$DestinationModelToJson(this);

  Destination toEntity() => Destination(
        id: id,
        name: name,
        imageUrl: imageUrl,
        placeholderColor: placeholderColor,
        averageRating: averageRating,
        reviewCount: reviewCount,
      );
}
import 'package:json_annotation/json_annotation.dart';

import 'package:travel_advisor_mobile/features/place/domain/entities/place_review_entity.dart';

part 'place_review_model.g.dart';

@JsonSerializable()
class PlaceReviewModel {
  final String id;
  @JsonKey(name: 'user_name')
  final String userName;
  @JsonKey(name: 'user_avatar')
  final String userAvatar;
  final double rating;
  @JsonKey(name: 'time_ago')
  final String timeAgo;
  @JsonKey(name: 'review_text')
  final String reviewText;
  @JsonKey(name: 'review_images')
  final List<String> reviewImages;

  const PlaceReviewModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.timeAgo,
    required this.reviewText,
    this.reviewImages = const [],
  });

  factory PlaceReviewModel.fromJson(Map<String, dynamic> json) => _$PlaceReviewModelFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceReviewModelToJson(this);

  PlaceReviewEntity toEntity() => PlaceReviewEntity(
    id: id,
    userName: userName,
    userAvatar: userAvatar,
    rating: rating,
    timeAgo: timeAgo,
    reviewText: reviewText,
    reviewImages: reviewImages,
  );
}
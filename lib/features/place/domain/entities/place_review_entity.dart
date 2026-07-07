import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_review_entity.freezed.dart';

@freezed
class PlaceReviewEntity with _$PlaceReviewEntity {
  const factory PlaceReviewEntity({
    required String id,
    required String userName,
    required String userAvatar,
    required double rating,
    required String timeAgo,
    required String reviewText,
    String? provider,
    @Default('approved') String status,
    @Default([]) List<String> reviewImages,
  }) = _PlaceReviewEntity;
}

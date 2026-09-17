import 'package:freezed_annotation/freezed_annotation.dart';

import 'violation_media_item.dart';

part 'notification_entity.freezed.dart';

@freezed
class NotificationEntity with _$NotificationEntity {
  const factory NotificationEntity({
    required String id,
    required String title,
    required String content,
    required String notificationType,
    required String timeLabel,
    required bool isUnread,
    required String iconKey,
    String? actionType,
    String? actionLabel,
    String? targetType,
    String? placeId,
    String? itineraryId,
    String? itineraryDetailId,
    @Default(false) bool hasPlaceReview,
    @Default(false) bool hasItineraryReview,
    @Default(<ViolationMediaItem>[]) List<ViolationMediaItem> violationMedia,
  }) = _NotificationEntity;
}

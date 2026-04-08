import 'package:freezed_annotation/freezed_annotation.dart';

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
  }) = _NotificationEntity;
}

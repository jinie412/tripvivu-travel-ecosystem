import 'package:json_annotation/json_annotation.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel {
  final String id;
  final String title;
  final String content;
  @JsonKey(name: 'notification_type')
  final String notificationType;
  final String status;
  @JsonKey(name: 'is_global')
  final bool isGlobal;
  @JsonKey(name: 'read_at')
  final String? readAt;
  @JsonKey(name: 'sent_at')
  final String sentAt;
  @JsonKey(name: 'time_label')
  final String timeLabel;
  @JsonKey(name: 'icon_key')
  final String iconKey;
  @JsonKey(name: 'is_unread')
  final bool isUnread;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.notificationType,
    required this.status,
    required this.isGlobal,
    this.readAt,
    required this.sentAt,
    required this.timeLabel,
    required this.iconKey,
    required this.isUnread,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  NotificationEntity toEntity() => NotificationEntity(
    id: id,
    title: title,
    content: content,
    notificationType: notificationType,
    timeLabel: timeLabel,
    isUnread: isUnread,
    iconKey: iconKey,
  );
}

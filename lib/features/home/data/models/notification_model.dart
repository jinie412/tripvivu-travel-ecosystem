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
  @JsonKey(name: 'action_type')
  final String? actionType;
  @JsonKey(name: 'action_label')
  final String? actionLabel;
  @JsonKey(name: 'target_type')
  final String? targetType;
  @JsonKey(name: 'place_id')
  final String? placeId;
  @JsonKey(name: 'itinerary_id')
  final String? itineraryId;
  @JsonKey(name: 'itinerary_detail_id')
  final String? itineraryDetailId;
  @JsonKey(name: 'has_place_review')
  final bool hasPlaceReview;
  @JsonKey(name: 'has_itinerary_review')
  final bool hasItineraryReview;

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
    this.actionType,
    this.actionLabel,
    this.targetType,
    this.placeId,
    this.itineraryId,
    this.itineraryDetailId,
    this.hasPlaceReview = false,
    this.hasItineraryReview = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? '').toString().toLowerCase();
    final normalizedJson = Map<String, dynamic>.from(json);
    final metadata = json['metadata'];

    if (metadata is Map<String, dynamic>) {
      normalizedJson['action_label'] ??= metadata['action_label'];
      normalizedJson['place_id'] ??= metadata['place_id'];
      normalizedJson['itinerary_id'] ??= metadata['itinerary_id'];
      normalizedJson['itinerary_detail_id'] ??= metadata['itinerary_detail_id'];
      normalizedJson['has_place_review'] ??= metadata['has_place_review'];
      normalizedJson['has_itinerary_review'] ??=
          metadata['has_itinerary_review'];
    }
    normalizedJson['has_place_review'] =
        normalizedJson['has_place_review'] == true;
    normalizedJson['has_itinerary_review'] =
        normalizedJson['has_itinerary_review'] == true;

    if (status == 'read' || json['read_at'] != null) {
      normalizedJson['is_unread'] = false;
    } else {
      normalizedJson['is_unread'] = json['is_unread'] == true;
    }

    return _$NotificationModelFromJson(normalizedJson);
  }

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  NotificationEntity toEntity() => NotificationEntity(
    id: id,
    title: title,
    content: content,
    notificationType: notificationType,
    timeLabel: timeLabel,
    isUnread: isUnread,
    iconKey: iconKey,
    actionType: actionType,
    actionLabel: actionLabel,
    targetType: targetType,
    placeId: placeId,
    itineraryId: itineraryId,
    itineraryDetailId: itineraryDetailId,
    hasPlaceReview: hasPlaceReview,
    hasItineraryReview: hasItineraryReview,
  );
}

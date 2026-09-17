import 'package:json_annotation/json_annotation.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/violation_media_item.dart';

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
  @JsonKey(name: 'violation_media')
  final List<Map<String, dynamic>>? violationMedia;

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
    this.violationMedia,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? '').toString().toLowerCase();
    final normalizedJson = Map<String, dynamic>.from(json);
    final metadata = json['metadata'];

    normalizedJson['id'] = (normalizedJson['id'] ?? '').toString();
    normalizedJson['title'] = (normalizedJson['title'] ?? 'Thông báo')
        .toString();
    normalizedJson['content'] = (normalizedJson['content'] ?? '').toString();
    normalizedJson['notification_type'] =
        (normalizedJson['notification_type'] ?? 'system').toString();
    normalizedJson['status'] = (normalizedJson['status'] ?? 'unread')
        .toString();
    normalizedJson['is_global'] = normalizedJson['is_global'] == true;
    normalizedJson['sent_at'] =
        (normalizedJson['sent_at'] ?? DateTime.now().toIso8601String())
            .toString();
    normalizedJson['time_label'] = (normalizedJson['time_label'] ?? 'Vừa xong')
        .toString();
    normalizedJson['icon_key'] = (normalizedJson['icon_key'] ?? 'info')
        .toString();

    if (metadata is Map) {
      final metadataJson = Map<String, dynamic>.from(metadata);
      normalizedJson['action_label'] ??= metadataJson['action_label'];
      normalizedJson['place_id'] ??= metadataJson['place_id'];
      normalizedJson['itinerary_id'] ??= metadataJson['itinerary_id'];
      normalizedJson['itinerary_detail_id'] ??=
          metadataJson['itinerary_detail_id'];
      normalizedJson['has_place_review'] ??= metadataJson['has_place_review'];
      normalizedJson['has_itinerary_review'] ??=
          metadataJson['has_itinerary_review'];
      final violationMediaRaw = metadataJson['violation_media'];
      if (violationMediaRaw is List) {
        normalizedJson['violation_media'] = violationMediaRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      final shareStatus = metadataJson['share_status'];
      if (shareStatus == 'accepted') {
        normalizedJson['action_type'] = 'itinerary_share_accepted';
      } else if (shareStatus == 'rejected') {
        normalizedJson['action_type'] = 'itinerary_share_rejected';
      }
    }
    for (final key in [
      'read_at',
      'action_type',
      'action_label',
      'target_type',
      'place_id',
      'itinerary_id',
      'itinerary_detail_id',
    ]) {
      final value = normalizedJson[key];
      if (value != null) normalizedJson[key] = value.toString();
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
    violationMedia: (violationMedia ?? const [])
        .map(
          (m) => ViolationMediaItem(
            url: (m['url'] ?? '').toString(),
            mediaType: m['media_type'] == 'video'
                ? ViolationMediaType.video
                : ViolationMediaType.image,
            categories: ((m['categories'] as List?) ?? const [])
                .map((c) => c.toString())
                .toList(),
          ),
        )
        .where((item) => item.url.isNotEmpty)
        .toList(),
  );
}

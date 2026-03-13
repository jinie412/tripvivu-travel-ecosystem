import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_item_entity.freezed.dart';

enum ActivityType { itinerary, rated, reviewPending, food }
enum ActivityStatus { none, upcoming, preparing, delivered, pendingReview }

@freezed
class ActivityItemEntity with _$ActivityItemEntity {
  const factory ActivityItemEntity({
    required String id,
    required String title,
    required ActivityType type,
    double? rating,
    DateTime? date,
    @Default(ActivityStatus.none) ActivityStatus status,
    String? code,
  }) = _ActivityItemEntity;
}

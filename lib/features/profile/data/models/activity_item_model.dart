import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/activity_item_entity.dart';

part 'activity_item_model.g.dart';

@JsonSerializable()
class ActivityItemModel {
  final String id;
  final String title;
  final ActivityType type;
  final double? rating;
  final DateTime? date;
  @JsonKey(defaultValue: ActivityStatus.none)
  final ActivityStatus status;
  final String? code;

  const ActivityItemModel({
    required this.id,
    required this.title,
    required this.type,
    this.rating,
    this.date,
    this.status = ActivityStatus.none,
    this.code,
  });

  factory ActivityItemModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityItemModelToJson(this);

  ActivityItemEntity toEntity() => ActivityItemEntity(
        id: id,
        title: title,
        type: type,
        rating: rating,
        date: date,
        status: status,
        code: code,
      );
}

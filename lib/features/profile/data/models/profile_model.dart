import 'package:json_annotation/json_annotation.dart';

import 'package:travel_advisor_mobile/features/profile/domain/entities/profile_entity.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class ProfileModel {
  final String id;
  final String name;
  final String email;
  @JsonKey(name: 'avatar_url')
  final String avatarUrl;
  @JsonKey(name: 'membership_tier')
  final String membershipTier;
  @JsonKey(name: 'review_pending_count')
  final int reviewPendingCount;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.membershipTier,
    required this.reviewPendingCount,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);

  ProfileEntity toEntity() => ProfileEntity(
        id: id,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        membershipTier: membershipTier,
        reviewPendingCount: reviewPendingCount,
      );
}
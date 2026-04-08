import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_entity.freezed.dart';

@freezed
class ProfileEntity with _$ProfileEntity {
  const factory ProfileEntity({
    required String id,
    required String name,
    required String email,
    required String avatarUrl,
    required String membershipTier,
    required int reviewPendingCount,
    String? gender,
    String? phoneNumber,
    List<String>? travelPreferences,
  }) = _ProfileEntity;
}

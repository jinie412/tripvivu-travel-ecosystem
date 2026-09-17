import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

/// Domain entity — pure business model, no JSON logic here.
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    required String displayName,
    String? avatarUrl,
    String? role,
    String? phone,
    String? gender,
  }) = _UserEntity;
}
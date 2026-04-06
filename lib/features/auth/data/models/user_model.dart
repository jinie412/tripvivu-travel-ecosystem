import 'package:json_annotation/json_annotation.dart';

import 'package:travel_advisor_mobile/features/auth/domain/entities/user_entity.dart';

part 'user_model.g.dart';

/// Data Transfer Object for [UserEntity].
/// Maps the backend API response to a Dart object.
/// Backend login response: { user: { id, email, role, phone, fullName, gender, avatar_url } }
@JsonSerializable()
class UserModel {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'email')
  final String email;

  /// Backend trả về `fullName`, không phải `display_name`
  @JsonKey(name: 'fullName')
  final String? fullName;

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  @JsonKey(name: 'role')
  final String? role;

  @JsonKey(name: 'phone')
  final String? phone;

  @JsonKey(name: 'gender')
  final String? gender;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.role,
    this.phone,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Convert to domain entity (used by repository implementation).
  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        displayName: fullName ?? email,
        avatarUrl: avatarUrl,
        role: role,
        phone: phone,
        gender: gender,
      );
}
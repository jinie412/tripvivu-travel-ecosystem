import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

/// Data Transfer Object for [UserEntity].
/// Handles JSON ↔ Dart mapping from the API response.
/// The domain layer never sees this class directly.
@JsonSerializable()
class UserModel {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'display_name')
  final String displayName;

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Convert to domain entity (used by repository implementation).
  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
}

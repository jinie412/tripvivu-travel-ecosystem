import 'package:equatable/equatable.dart';

import 'package:travel_advisor_mobile/features/profile/domain/entities/activity_item_entity.dart';
import 'package:travel_advisor_mobile/features/profile/domain/entities/profile_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  final List<ActivityItemEntity> activities;
  final bool isAvatarUploading;

  const ProfileLoaded({
    required this.profile,
    required this.activities,
    this.isAvatarUploading = false,
  });

  ProfileLoaded copyWith({
    ProfileEntity? profile,
    List<ActivityItemEntity>? activities,
    bool? isAvatarUploading,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      activities: activities ?? this.activities,
      isAvatarUploading: isAvatarUploading ?? this.isAvatarUploading,
    );
  }

  @override
  List<Object?> get props => [profile, activities, isAvatarUploading];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileUpdateSuccess extends ProfileState {
  const ProfileUpdateSuccess();
}

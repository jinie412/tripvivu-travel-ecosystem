import 'package:equatable/equatable.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/activity_item_entity.dart';

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

  const ProfileLoaded({
    required this.profile,
    required this.activities,
  });

  @override
  List<Object?> get props => [profile, activities];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

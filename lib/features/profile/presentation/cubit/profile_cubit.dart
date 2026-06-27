import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_state.dart';

import 'package:travel_advisor_mobile/features/profile/domain/entities/activity_item_entity.dart';

import 'package:travel_advisor_mobile/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:travel_advisor_mobile/features/profile/domain/usecases/get_recent_activities_usecase.dart';
import 'package:travel_advisor_mobile/features/profile/domain/usecases/upload_avatar_usecase.dart';
import 'package:travel_advisor_mobile/features/profile/domain/usecases/update_profile_usecase.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase _getProfile;
  final GetRecentActivitiesUseCase _getRecentActivities;
  final UploadAvatarUseCase _uploadAvatar;
  final UpdateProfileUseCase _updateProfile;

  ProfileCubit({
    required GetProfileUseCase getProfile,
    required GetRecentActivitiesUseCase getRecentActivities,
    required UploadAvatarUseCase uploadAvatar,
    required UpdateProfileUseCase updateProfile,
  }) : _getProfile = getProfile,
       _getRecentActivities = getRecentActivities,
       _uploadAvatar = uploadAvatar,
       _updateProfile = updateProfile,
       super(const ProfileInitial());

  Future<void> loadProfile({bool includeActivities = false}) async {
    if (isClosed) return;
    emit(const ProfileLoading());
    try {
      var profile = await _getProfile();
      var activities = const <ActivityItemEntity>[];

      if (includeActivities) {
        try {
          activities = await _getRecentActivities();
          final pendingCount = activities
              .where((item) => item.type == ActivityType.reviewPending)
              .length;
          profile = profile.copyWith(reviewPendingCount: pendingCount);
        } catch (_) {
          activities = const <ActivityItemEntity>[];
        }
      }

      if (isClosed) return;
      emit(ProfileLoaded(profile: profile, activities: activities));
    } catch (e) {
      if (isClosed) return;
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> uploadNewAvatar(XFile image) async {
    if (state is! ProfileLoaded) return;
    final currentState = state as ProfileLoaded;
    if (isClosed) return;

    emit(currentState.copyWith(isAvatarUploading: true));
    try {
      final uploadedAvatarUrl = (await _uploadAvatar(image.path)).trim();
      final displayAvatarUrl = uploadedAvatarUrl.isEmpty
          ? currentState.profile.avatarUrl
          : _withCacheBuster(uploadedAvatarUrl);

      if (isClosed) return;
      emit(
        currentState.copyWith(
          profile: currentState.profile.copyWith(avatarUrl: displayAvatarUrl),
          isAvatarUploading: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(currentState.copyWith(isAvatarUploading: false));
      rethrow;
    }
  }

  String _withCacheBuster(String url) {
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> updateProfile({
    String? displayName,
    String? gender,
    List<String>? travelPreferences,
  }) async {
    final currentState = state;
    if (isClosed || currentState is! ProfileLoaded) return;

    try {
      final updatedProfile = await _updateProfile(
        displayName: displayName,
        gender: gender,
        travelPreferences: travelPreferences,
      );

      if (isClosed) return;
      emit(
        currentState.copyWith(
          profile: currentState.profile.copyWith(
            name: displayName?.trim().isNotEmpty == true
                ? displayName!.trim()
                : updatedProfile.name.isNotEmpty
                ? updatedProfile.name
                : currentState.profile.name,
            gender:
                gender ?? updatedProfile.gender ?? currentState.profile.gender,
            travelPreferences:
                travelPreferences ??
                updatedProfile.travelPreferences ??
                currentState.profile.travelPreferences,
          ),
        ),
      );
    } catch (_) {
      rethrow;
    }
  }
}

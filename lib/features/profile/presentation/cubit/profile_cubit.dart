import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_state.dart';

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

  Future<void> loadProfile() async {
    if (isClosed) return;
    emit(const ProfileLoading());
    try {
      final results = await Future.wait([
        _getProfile(),
        _getRecentActivities(),
      ]);

      if (isClosed) return;
      emit(
        ProfileLoaded(
          profile: results[0] as dynamic,
          activities: results[1] as dynamic,
        ),
      );
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
      await _uploadAvatar(image.path);

      final results = await Future.wait([
        _getProfile(),
        _getRecentActivities(),
      ]);

      if (isClosed) return;
      emit(
        ProfileLoaded(
          profile: results[0] as dynamic,
          activities: results[1] as dynamic,
          isAvatarUploading: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? gender,
    List<String>? travelPreferences,
  }) async {
    if (isClosed) return;
    emit(const ProfileLoading());
    try {
      await _updateProfile(
        displayName: displayName,
        gender: gender,
        travelPreferences: travelPreferences,
      );
      if (isClosed) return;
      emit(const ProfileUpdateSuccess());
    } catch (e) {
      if (isClosed) return;
      emit(ProfileError(e.toString()));
    }
  }
}

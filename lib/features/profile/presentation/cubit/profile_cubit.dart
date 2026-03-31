import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_state.dart';

import 'package:travel_advisor_mobile/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:travel_advisor_mobile/features/profile/domain/usecases/get_recent_activities_usecase.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase _getProfile;
  final GetRecentActivitiesUseCase _getRecentActivities;

  ProfileCubit({
    required GetProfileUseCase getProfile,
    required GetRecentActivitiesUseCase getRecentActivities,
  })  : _getProfile = getProfile,
        _getRecentActivities = getRecentActivities,
        super(const ProfileInitial());

  Future<void> loadProfile() async {
    emit(const ProfileLoading());
    try {
      final results = await Future.wait([
        _getProfile(),
        _getRecentActivities(),
      ]);
      
      emit(ProfileLoaded(
        profile: results[0] as dynamic,
        activities: results[1] as dynamic,
      ));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
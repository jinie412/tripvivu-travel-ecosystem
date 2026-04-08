import 'package:travel_advisor_mobile/features/profile/domain/entities/activity_item_entity.dart';
import 'package:travel_advisor_mobile/features/profile/domain/entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile();
  Future<List<ActivityItemEntity>> getRecentActivities();
  Future<String> uploadAvatar(String imagePath);
  Future<ProfileEntity> updateProfile({
    String? displayName,
    String? gender,
    List<String>? travelPreferences,
  });
}

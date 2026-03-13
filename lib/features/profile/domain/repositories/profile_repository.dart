import '../entities/profile_entity.dart';
import '../entities/activity_item_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile();
  Future<List<ActivityItemEntity>> getRecentActivities();
}

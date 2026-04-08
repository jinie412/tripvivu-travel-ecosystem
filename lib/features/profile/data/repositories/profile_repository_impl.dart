import 'package:travel_advisor_mobile/features/profile/data/datasources/profile_datasource.dart';
import 'package:travel_advisor_mobile/features/profile/domain/entities/activity_item_entity.dart';
import 'package:travel_advisor_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:travel_advisor_mobile/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepositoryImpl(this.dataSource);

  @override
  Future<ProfileEntity> getProfile() async {
    final model = await dataSource.getProfile();
    return model.toEntity();
  }

  @override
  Future<List<ActivityItemEntity>> getRecentActivities() async {
    final models = await dataSource.getRecentActivities();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<String> uploadAvatar(String imagePath) {
    return dataSource.uploadAvatar(imagePath);
  }

  @override
  Future<ProfileEntity> updateProfile({
    String? displayName,
    String? gender,
    List<String>? travelPreferences,
  }) async {
    final model = await dataSource.updateProfile(
      displayName: displayName,
      gender: gender,
      travelPreferences: travelPreferences,
    );
    return model.toEntity();
  }
}

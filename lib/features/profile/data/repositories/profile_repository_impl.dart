import '../../domain/entities/activity_item_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_datasource.dart';

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
}

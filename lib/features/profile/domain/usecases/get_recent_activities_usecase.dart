import '../entities/activity_item_entity.dart';
import '../repositories/profile_repository.dart';

class GetRecentActivitiesUseCase {
  final ProfileRepository repository;

  GetRecentActivitiesUseCase(this.repository);

  Future<List<ActivityItemEntity>> call() {
    return repository.getRecentActivities();
  }
}

import 'package:travel_advisor_mobile/features/profile/domain/entities/activity_item_entity.dart';
import 'package:travel_advisor_mobile/features/profile/domain/repositories/profile_repository.dart';

class GetRecentActivitiesUseCase {
  final ProfileRepository repository;

  GetRecentActivitiesUseCase(this.repository);

  Future<List<ActivityItemEntity>> call() {
    return repository.getRecentActivities();
  }
}
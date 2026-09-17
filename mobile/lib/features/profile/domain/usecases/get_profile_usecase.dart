import 'package:travel_advisor_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:travel_advisor_mobile/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<ProfileEntity> call() {
    return repository.getProfile();
  }
}
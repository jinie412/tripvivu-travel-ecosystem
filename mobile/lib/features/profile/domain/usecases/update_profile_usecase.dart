import 'package:travel_advisor_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:travel_advisor_mobile/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<ProfileEntity> call({
    String? displayName,
    String? gender,
    List<String>? travelPreferences,
  }) {
    return repository.updateProfile(
      displayName: displayName,
      gender: gender,
      travelPreferences: travelPreferences,
    );
  }
}

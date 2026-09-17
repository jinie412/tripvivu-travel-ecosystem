import 'package:travel_advisor_mobile/features/profile/domain/repositories/profile_repository.dart';

class UploadAvatarUseCase {
  final ProfileRepository repository;

  UploadAvatarUseCase(this.repository);

  Future<String> call(String imagePath) {
    return repository.uploadAvatar(imagePath);
  }
}

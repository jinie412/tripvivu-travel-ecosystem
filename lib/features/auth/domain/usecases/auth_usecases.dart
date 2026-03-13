import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use-case: Login. Presentation calls this — not the repository directly.
class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<UserEntity> call({
    required String emailOrPhone,
    required String password,
  }) {
    return _repository.login(
      emailOrPhone: emailOrPhone,
      password: password,
    );
  }
}

/// Use-case: Register.
class RegisterUseCase {
  final AuthRepository _repository;
  RegisterUseCase(this._repository);

  Future<UserEntity> call({
    required String emailOrPhone,
    required String password,
  }) {
    return _repository.register(
      emailOrPhone: emailOrPhone,
      password: password,
    );
  }
}
